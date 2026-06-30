//
//  BreakoutRoomsManager.swift
//  RealtimeKitUI
//

import RealtimeKit
import UIKit

// MARK: - DraftMeeting

struct DraftMeeting {
    let id: String // "temp-<UUID>" for drafts, server ID for existing rooms
    var title: String
    let isParent: Bool
    let isDraft: Bool // true = not yet created on server
}

// MARK: - Participant identifier helper

extension RtkConnectedMeetingParticipant {
    /// Use customParticipantId when available, fall back to server peer id.
    var identifier: String {
        customParticipantId.isEmpty ? id : customParticipantId
    }
}

// MARK: - BreakoutRoomsManager

/// Manages local draft state for breakout rooms.
/// Mirrors the Android BreakoutRoomsManager — keeps a mutable draft of rooms and
/// participant assignments that can be committed to the server via applyChanges().
final class BreakoutRoomsManager {
    // MARK: State

    /// All rooms keyed by id (parent + children, drafts + server rooms)
    private(set) var allMeetingsMap: [String: DraftMeeting] = [:]

    /// room id → set of participant identifiers assigned to that room (draft state)
    private(set) var meetingParticipantsMap: [String: Set<String>] = [:]

    /// identifier → room id they are currently assigned to (draft)
    private(set) var participantsCurrentMeetingMap: [String: String] = [:]

    /// identifier → room id from server (for diff on apply)
    private(set) var participantsOriginalMeetingMap: [String: String] = [:]

    /// All known participants keyed by identifier
    private(set) var allParticipantsMap: [String: RtkConnectedMeetingParticipant] = [:]

    /// Server room ids to delete when applying changes
    private(set) var meetingsToDelete: Set<String> = []

    /// Whether there are unsaved local changes
    private(set) var hasLocalChanges = false

    /// The parent (main) room id
    private(set) var parentMeetingId: String?

    // MARK: Room counter for title generation

    private var roomCounter = 0

    // MARK: - Derived state

    /// All child rooms (excludes parent), sorted by title with natural number ordering
    /// so "Room 1" < "Room 2" < "Room 10" regardless of insertion or server ID order.
    var allConnectedMeetings: [DraftMeeting] {
        allMeetingsMap.values
            .filter { !$0.isParent }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    /// Participants not assigned to any child room (assigned to parent = unassigned)
    var unassignedParticipants: [RtkConnectedMeetingParticipant] {
        guard let parentId = parentMeetingId else { return [] }
        let identifiers = meetingParticipantsMap[parentId] ?? []
        return identifiers.compactMap { allParticipantsMap[$0] }
            .sorted { $0.displayName < $1.displayName }
    }

    /// Participants in a specific room
    func participants(inMeeting id: String) -> [RtkConnectedMeetingParticipant] {
        let identifiers = meetingParticipantsMap[id] ?? []
        return identifiers.compactMap { allParticipantsMap[$0] }
            .sorted { $0.displayName < $1.displayName }
    }

    /// Returns the room id that the given participant (identified by SDK userId, which may be either
    /// their peer id or customParticipantId) is currently assigned to.
    func currentRoomId(forUserId userId: String) -> String? {
        for (identifier, participant) in allParticipantsMap {
            if participant.id == userId || participant.customParticipantId == userId {
                return participantsCurrentMeetingMap[identifier]
            }
        }
        return nil
    }

    // MARK: - Initialisation from server

    /// Full reset from server state. Clears all draft state.
    func initializeFromServer(parentMeeting: RtkConnectedMeeting?, meetings: [RtkConnectedMeeting]) {
        allMeetingsMap.removeAll()
        meetingParticipantsMap.removeAll()
        participantsCurrentMeetingMap.removeAll()
        participantsOriginalMeetingMap.removeAll()
        allParticipantsMap.removeAll()
        meetingsToDelete.removeAll()
        hasLocalChanges = false

        var counter = 0

        func ingest(_ meeting: RtkConnectedMeeting, isParent: Bool) {
            allMeetingsMap[meeting.id] = DraftMeeting(
                id: meeting.id,
                title: meeting.title,
                isParent: isParent,
                isDraft: false,
            )
            var ids = Set<String>()
            for participant in meeting.participants {
                allParticipantsMap[participant.identifier] = participant
                participantsCurrentMeetingMap[participant.identifier] = meeting.id
                participantsOriginalMeetingMap[participant.identifier] = meeting.id
                ids.insert(participant.identifier)
            }
            meetingParticipantsMap[meeting.id] = ids
            if !isParent { counter += 1 }
        }

        if let parent = parentMeeting {
            parentMeetingId = parent.id
            ingest(parent, isParent: true)
        }
        for meeting in meetings {
            ingest(meeting, isParent: false)
        }
        roomCounter = counter
    }

    /// Additive merge when local changes exist; full reset otherwise.
    func updateFromServer(parentMeeting: RtkConnectedMeeting?, meetings: [RtkConnectedMeeting]) {
        // Guard: skip empty snapshots during pre-live setup only (Step 1 stepper changes can
        // trigger onStateUpdate before rooms are started, producing an empty participant list
        // that would wipe the seeded participant data). Once child rooms exist the guard is
        // lifted so that legitimate post-close or all-leave clears are processed normally.
        let incomingParticipantCount = (parentMeeting?.participants.count ?? 0)
            + meetings.flatMap { $0.participants }.count
        let hasActiveRooms = allMeetingsMap.values.contains { !$0.isParent }
        if !hasLocalChanges && incomingParticipantCount == 0 && !allParticipantsMap.isEmpty && !hasActiveRooms {
            return
        }

        if !hasLocalChanges {
            initializeFromServer(parentMeeting: parentMeeting, meetings: meetings)
            return
        }

        // Build the full set of identifiers the server currently knows about.
        var serverIdentifiers = Set<String>()
        func collectParticipants(from meeting: RtkConnectedMeeting) {
            for participant in meeting.participants {
                serverIdentifiers.insert(participant.identifier)
            }
        }
        if let parent = parentMeeting { collectParticipants(from: parent) }
        for meeting in meetings {
            collectParticipants(from: meeting)
        }

        /// Add new participants (arrivals since last sync).
        func addNewParticipants(from meeting: RtkConnectedMeeting) {
            for participant in meeting.participants {
                if allParticipantsMap[participant.identifier] == nil {
                    allParticipantsMap[participant.identifier] = participant
                    // New participant goes to parent (unassigned)
                    if let parentId = parentMeetingId {
                        meetingParticipantsMap[parentId, default: []].insert(participant.identifier)
                        participantsCurrentMeetingMap[participant.identifier] = parentId
                        participantsOriginalMeetingMap[participant.identifier] = parentId
                    }
                }
            }
        }
        if let parent = parentMeeting { addNewParticipants(from: parent) }
        for meeting in meetings {
            addNewParticipants(from: meeting)
        }

        // Remove participants who have left (departures since last sync).
        let departed = Set(allParticipantsMap.keys).subtracting(serverIdentifiers)
        for identifier in departed {
            if let currentRoom = participantsCurrentMeetingMap[identifier] {
                meetingParticipantsMap[currentRoom]?.remove(identifier)
            }
            participantsCurrentMeetingMap.removeValue(forKey: identifier)
            participantsOriginalMeetingMap.removeValue(forKey: identifier)
            allParticipantsMap.removeValue(forKey: identifier)
        }
    }

    // MARK: - Mutations

    /// Create N new draft rooms with auto-generated titles.
    func addNewMeetings(count: Int) {
        for _ in 0 ..< count {
            roomCounter += 1
            let tempId = "temp-\(UUID().uuidString)"
            allMeetingsMap[tempId] = DraftMeeting(
                id: tempId,
                title: "Room \(roomCounter)",
                isParent: false,
                isDraft: true,
            )
            meetingParticipantsMap[tempId] = []
        }
        hasLocalChanges = true
    }

    func addNewMeeting() {
        addNewMeetings(count: 1)
    }

    /// Delete a room: removes draft or marks server room for deletion. Moves its participants to parent.
    /// Callers must not invoke this on the parent meeting — guard at call site; this is a defensive belt-and-suspenders check.
    func deleteMeeting(id: String) {
        guard let meeting = allMeetingsMap[id], !meeting.isParent else { return }
        guard let parentId = parentMeetingId else { return }
        // Move all participants back to parent
        let participants = meetingParticipantsMap[id] ?? []
        for identifier in participants {
            participantsCurrentMeetingMap[identifier] = parentId
            meetingParticipantsMap[parentId, default: []].insert(identifier)
        }
        meetingParticipantsMap.removeValue(forKey: id)
        allMeetingsMap.removeValue(forKey: id)
        if meeting.isDraft == false {
            meetingsToDelete.insert(id)
        }
        hasLocalChanges = true
    }

    /// Update the title of a room (local only — draft change).
    func updateTitle(ofMeeting id: String, to title: String) {
        guard var meeting = allMeetingsMap[id] else { return }
        meeting.title = title
        allMeetingsMap[id] = meeting
        hasLocalChanges = true
    }

    /// Assign the given participant identifiers to a room.
    func assignParticipants(identifiers: [String], toMeeting meetingId: String) {
        for identifier in identifiers {
            // Remove from current room
            if let currentRoom = participantsCurrentMeetingMap[identifier] {
                meetingParticipantsMap[currentRoom]?.remove(identifier)
            }
            // Add to destination
            participantsCurrentMeetingMap[identifier] = meetingId
            meetingParticipantsMap[meetingId, default: []].insert(identifier)
        }
        hasLocalChanges = true
    }

    /// Move the given identifiers back to the parent (unassign them).
    func unassignParticipants(identifiers: [String]) {
        guard let parentId = parentMeetingId else { return }
        assignParticipants(identifiers: identifiers, toMeeting: parentId)
    }

    /// Move all participants from child rooms back to parent.
    func unassignAllParticipants() {
        guard let parentId = parentMeetingId else { return }
        let childIds = allMeetingsMap.keys.filter { allMeetingsMap[$0]?.isParent == false }
        for childId in childIds {
            let participants = Array(meetingParticipantsMap[childId] ?? [])
            unassignParticipants(identifiers: participants)
            // unassignParticipants already moves them to parent, so clear child set
            meetingParticipantsMap[childId] = []
        }
        // Rebuild parent set
        var all = Set<String>()
        for identifier in allParticipantsMap.keys {
            all.insert(identifier)
        }
        meetingParticipantsMap[parentId] = all
        for identifier in all {
            participantsCurrentMeetingMap[identifier] = parentId
        }
    }

    /// Round-robin distribute unassigned participants across child rooms.
    func assignParticipantsRandomly() {
        guard let parentId = parentMeetingId else { return }
        let childIds = allMeetingsMap.values
            .filter { !$0.isParent }
            .map(\.id)
        guard !childIds.isEmpty else { return }

        let unassigned = Array(meetingParticipantsMap[parentId] ?? [])
        for (index, identifier) in unassigned.enumerated() {
            let targetId = childIds[index % childIds.count]
            assignParticipants(identifiers: [identifier], toMeeting: targetId)
        }
    }

    /// Discard all local changes (caller must re-fetch from server).
    /// Use this when breakout is already live — preserves server rooms, clears dirty flag only.
    func discardChanges() {
        hasLocalChanges = false
    }

    /// Wipe all state back to empty.
    /// Use this when going back from Step 2 to Step 1 before any server commit has happened.
    func reset() {
        allMeetingsMap.removeAll()
        meetingParticipantsMap.removeAll()
        participantsCurrentMeetingMap.removeAll()
        participantsOriginalMeetingMap.removeAll()
        allParticipantsMap.removeAll()
        meetingsToDelete.removeAll()
        hasLocalChanges = false
        parentMeetingId = nil
        roomCounter = 0
    }

    // MARK: - Apply changes to server

    /// Commit all draft changes to the server.
    /// - Steps: 1) create draft rooms, 2) move participants, 3) delete removed rooms
    func applyChanges(
        meeting: RealtimeKitClient,
        onComplete: @escaping (ConnectedMeetingsError?) -> Void,
    ) {
        let drafts = allMeetingsMap.values.filter(\.isDraft)
        let draftTitles = drafts.map(\.title)

        func applyMoves(completion: @escaping (ConnectedMeetingsError?) -> Void) {
            // Build (source, dest) → [participantId] map
            // participantId here is the server peer id (RtkConnectedMeetingParticipant.id)
            var moveMap: [String: [String: [String]]] = [:] // [sourceId: [destId: [peerId]]]
            for (identifier, destId) in participantsCurrentMeetingMap {
                let srcId = participantsOriginalMeetingMap[identifier]
                if srcId == nil || srcId == destId { continue }
                let src = srcId!
                let peerId = allParticipantsMap[identifier]?.id ?? identifier
                moveMap[src, default: [:]][destId, default: []].append(peerId)
            }
            let moves = moveMap.flatMap { src, dests in dests.map { dest, peerIds in (src, dest, peerIds) } }
            guard !moves.isEmpty else { completion(nil); return }

            let group = DispatchGroup()
            var firstError: ConnectedMeetingsError?
            let lock = NSLock()
            for (src, dest, peerIds) in moves {
                group.enter()
                meeting.connectedMeetings.moveParticipants(
                    sourceMeetingId: src,
                    destinationMeetingId: dest,
                    participantIds: peerIds,
                ) { error in
                    if let error {
                        lock.lock()
                        if firstError == nil { firstError = error }
                        lock.unlock()
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) { completion(firstError) }
        }

        func applyDeletes(completion: @escaping (ConnectedMeetingsError?) -> Void) {
            let ids = Array(meetingsToDelete)
            guard !ids.isEmpty else { completion(nil); return }
            meeting.connectedMeetings.deleteMeetings(meetingIds: ids) { error in
                DispatchQueue.main.async { completion(error) }
            }
        }

        if draftTitles.isEmpty {
            // No rooms to create — go straight to moves then deletes
            applyMoves { moveError in
                if let moveError { onComplete(moveError); return }
                applyDeletes { deleteError in
                    if let deleteError { onComplete(deleteError); return }
                    self.hasLocalChanges = false
                    onComplete(nil)
                }
            }
            return
        }

        // 1) Create draft rooms
        // ResultFailure/ResultSuccess are ObjC subclasses of Result; their generic parameters are
        // erased at runtime. Cast via AnyObject to bypass Swift's static type analysis and use
        // ObjC isKindOfClass dispatch instead.
        meeting.connectedMeetings.createMeetings(titles: draftTitles) { [weak self] result in
            if let failure = result as AnyObject as? ResultFailure<ConnectedMeetingsError> {
                DispatchQueue.main.async { onComplete(failure.value) }
                return
            }
            let createdRooms = (result as AnyObject as? ResultSuccess<NSArray>)?.value as? [RtkConnectedMeeting] ?? []
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                // Remap temp IDs to real IDs.
                // The SDK does not guarantee that created rooms are returned in the same
                // order as the submitted titles, so match by title rather than by index.
                // Duplicate-title drafts consume matching rooms in submission order; any
                // room whose title cannot be found falls back to the next unmatched room.
                guard createdRooms.count == drafts.count else {
                    // Count mismatch: can't reliably remap without risking misassignment.
                    // Clear the dirty flag and let the caller refresh from the server.
                    hasLocalChanges = false
                    onComplete(nil)
                    return
                }
                var remainingCreated = createdRooms
                for draft in drafts {
                    // Prefer a title match; fall back to the next available room.
                    let matchIdx = remainingCreated.firstIndex(where: { $0.title == draft.title }) ?? 0
                    guard matchIdx < remainingCreated.count else { continue }
                    let real = remainingCreated.remove(at: matchIdx)
                    // Move participants from temp id to real id
                    let participants = meetingParticipantsMap[draft.id] ?? []
                    meetingParticipantsMap[real.id] = participants
                    meetingParticipantsMap.removeValue(forKey: draft.id)
                    for identifier in participants {
                        if participantsCurrentMeetingMap[identifier] == draft.id {
                            participantsCurrentMeetingMap[identifier] = real.id
                        }
                    }
                    allMeetingsMap.removeValue(forKey: draft.id)
                    allMeetingsMap[real.id] = DraftMeeting(
                        id: real.id, title: real.title, isParent: false, isDraft: false,
                    )
                    // Original map has no entry for temp rooms — set to parent so diff picks up move
                    for identifier in participants {
                        if participantsOriginalMeetingMap[identifier] == nil {
                            participantsOriginalMeetingMap[identifier] = parentMeetingId ?? ""
                        }
                    }
                }

                // 2) Move participants
                applyMoves { moveError in
                    if let moveError { onComplete(moveError); return }
                    // 3) Delete rooms
                    applyDeletes { deleteError in
                        if let deleteError { onComplete(deleteError); return }
                        self.hasLocalChanges = false
                        onComplete(nil)
                    }
                }
            }
        }
    }

    /// Close all breakout rooms (delete all child rooms).
    func closeBreakout(meeting: RealtimeKitClient, onComplete: @escaping (ConnectedMeetingsError?) -> Void) {
        let childIds = allMeetingsMap.values
            .filter { !$0.isParent && !$0.isDraft }
            .map(\.id)
        meeting.connectedMeetings.deleteMeetings(meetingIds: childIds) { error in
            DispatchQueue.main.async { onComplete(error) }
        }
    }
}
