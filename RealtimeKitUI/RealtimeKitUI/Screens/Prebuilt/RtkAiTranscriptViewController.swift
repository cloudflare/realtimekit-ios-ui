//
//  RtkAiTranscriptViewController.swift
//  RealtimeKitUI
//

import RealtimeKit
import UIKit

// MARK: - Internal model

/// A rendered group: consecutive utterances from the same peer, concatenated.
private struct TranscriptGroup {
    let peerId: String
    let name: String
    let timestamp: Date
    var transcript: String
}

// MARK: - View controller

/// A view controller that displays a live, scrollable transcript of the current meeting.
///
/// Transcripts are seeded from `meeting.ai.transcripts` on load and updated in real time via
/// `RtkAiEventListener`. Consecutive utterances from the same participant are grouped into a
/// single bubble. A search bar allows filtering by participant name or transcript text.
///
/// Present this view controller modally (`.fullScreen`) or push it onto a navigation stack.
/// The `transcriptionEnabled` permission should be checked before presenting — see
/// `meeting.localUser.permissions.miscellaneous.transcriptionEnabled`.
public class RtkAiTranscriptViewController: RtkBaseViewController, SetTopbar {
    public let topBar: RtkNavigationBar = .init(title: "Transcripts")
    public var shouldShowTopBar: Bool = true

    // MARK: - State

    /// Reduced list of transcript entries (Web SDK `transcriptionsReducer` logic).
    private var entries: [RtkTranscriptionData] = []

    /// Cached result of the render-grouping pass. Invalidated whenever `entries` or
    /// `searchQuery` changes.
    private var cachedGroups: [TranscriptGroup] = []

    /// Search query — filters groups by participant name.
    private var searchQuery: String = "" {
        didSet {
            invalidateGroupCache()
            tableView.reloadData()
        }
    }

    /// Search debounce work item — cancelled and replaced on each keystroke.
    private var searchDebounceWork: DispatchWorkItem?

    /// When false the table does not auto-scroll; re-enabled once user reaches the bottom.
    private var autoScrollEnabled = true

    // MARK: - Group cache

    private func invalidateGroupCache() {
        let filtered = searchQuery.isEmpty
            ? entries
            : entries.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                    $0.transcript.localizedCaseInsensitiveContains(searchQuery)
            }

        var groups: [TranscriptGroup] = []
        for entry in filtered {
            if groups.isEmpty || groups[groups.count - 1].peerId != entry.peerId {
                groups.append(TranscriptGroup(
                    peerId: entry.peerId,
                    name: entry.name,
                    timestamp: Date(timeIntervalSince1970: Double(entry.timestamp) / 1000),
                    transcript: entry.transcript,
                ))
            } else {
                groups[groups.count - 1].transcript += " " + entry.transcript
            }
        }
        cachedGroups = groups
    }

    // MARK: - Views

    private let searchField: UITextField = {
        let field = UITextField()
        field.placeholder = "Search by name or transcript"
        field.borderStyle = .none
        field.font = UIFont.systemFont(ofSize: 14)
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .search
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private let searchContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.separatorStyle = .none
        tv.estimatedRowHeight = 80
        tv.rowHeight = UITableView.automaticDimension
        tv.allowsSelection = false
        tv.backgroundColor = .clear
        return tv
    }()

    private let emptyLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(text: "No transcripts yet", alignment: .center)
        label.textColor = DesignLibrary.shared.color.textColor.onBackground.shade600
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        topBar.set(.top(view, view.safeAreaInsets.top))
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignLibrary.shared.color.background.shade900
        addTopBar(dismissAnimation: true) { [weak self] in
            self?.dismiss(animated: true)
        }
        setupViews()
        loadHistoricalTranscripts()
        meeting.addAiEventListener(aiEventListener: self)
    }

    deinit {
        meeting.removeAiEventListener(aiEventListener: self)
    }

    // MARK: - Setup

    private func setupViews() {
        let space = DesignLibrary.shared.space
        let colors = DesignLibrary.shared.color
        let borderRadius = DesignLibrary.shared.borderRadius

        searchField.textColor = colors.textColor.onBackground.shade900
        searchField.attributedPlaceholder = NSAttributedString(
            string: "Search by name or transcript",
            attributes: [.foregroundColor: colors.textColor.onBackground.shade600],
        )
        searchField.addTarget(self, action: #selector(searchFieldChanged), for: .editingChanged)

        searchContainer.backgroundColor = colors.background.shade800
        searchContainer.layer.cornerRadius = borderRadius.getRadius(size: .one, radius: AppTheme.shared.cornerRadiusTypeNameTextField ?? .rounded)
        searchContainer.addSubview(searchField)
        searchField.set(
            .sameTopBottom(searchContainer, space.space2),
            .sameLeadingTrailing(searchContainer, space.space3),
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(RtkTranscriptGroupCell.self, forCellReuseIdentifier: RtkTranscriptGroupCell.reuseID)
        tableView.register(RtkTranscriptStartedCell.self, forCellReuseIdentifier: RtkTranscriptStartedCell.reuseID)

        view.addSubview(searchContainer)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        searchContainer.set(
            .below(topBar, space.space3),
            .sameLeadingTrailing(view, space.space3),
            .height(44),
        )
        tableView.set(
            .below(searchContainer, space.space2),
            .bottom(view),
            .sameLeadingTrailing(view),
        )
        emptyLabel.set(.centerView(view), .sameLeadingTrailing(view, space.space4))
    }

    private func loadHistoricalTranscripts() {
        for t in meeting.ai.transcripts {
            applyReducer(t)
        }
        invalidateGroupCache()
        updateEmptyState()
        tableView.reloadData()
        scrollToBottomIfEnabled(animated: false)
    }

    // MARK: - Reducer (matches Web SDK transcriptionsReducer)

    // Note: ai event listener is guaranteed to fire on the main thread by the SDK
    // (commit RTK-8099: "deliver AI transcript events on main thread via addAiEventListener").

    /// Applies the reducer in-place, avoiding the O(n) copy-per-call of a functional style.
    private func applyReducer(_ t: RtkTranscriptionData) {
        guard !entries.isEmpty, entries[entries.count - 1].peerId == t.peerId else {
            entries.append(t)
            return
        }
        if entries[entries.count - 1].id == t.id {
            entries[entries.count - 1] = t
        } else {
            entries.append(t)
        }
    }

    // MARK: - Helpers

    private func updateEmptyState() {
        emptyLabel.isHidden = !entries.isEmpty
    }

    private func scrollToBottomIfEnabled(animated: Bool) {
        guard autoScrollEnabled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            // Re-read count inside the closure so we never use a stale index.
            let count = cachedGroups.count
            guard count > 0 else { return }
            tableView.scrollToRow(at: IndexPath(row: count, section: 0), at: .bottom, animated: animated)
        }
    }

    @objc private func searchFieldChanged() {
        searchDebounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            searchQuery = searchField.text ?? ""
        }
        searchDebounceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }
}

// MARK: - RtkAiEventListener

extension RtkAiTranscriptViewController: RtkAiEventListener {
    public func onTranscript(transcriptionData: RtkTranscriptionData) {
        let oldGroupCount = cachedGroups.count
        applyReducer(transcriptionData)
        updateEmptyState()
        invalidateGroupCache()
        let newGroupCount = cachedGroups.count

        if oldGroupCount == newGroupCount, newGroupCount > 0 {
            // Last group updated in-place — row 0 is "Transcription started"
            tableView.reloadRows(at: [IndexPath(row: newGroupCount, section: 0)], with: .none)
        } else if newGroupCount == oldGroupCount + 1 {
            tableView.insertRows(at: [IndexPath(row: newGroupCount, section: 0)], with: .automatic)
        } else {
            tableView.reloadData()
        }
        scrollToBottomIfEnabled(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension RtkAiTranscriptViewController: UITableViewDataSource {
    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // Row 0: "Transcription started"; rows 1…N: groups
        cachedGroups.count + 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: RtkTranscriptStartedCell.reuseID, for: indexPath)
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RtkTranscriptGroupCell.reuseID, for: indexPath) as? RtkTranscriptGroupCell else {
            return UITableViewCell()
        }
        cell.configure(with: cachedGroups[indexPath.row - 1])
        return cell
    }
}

// MARK: - UITableViewDelegate (auto-scroll management)

extension RtkAiTranscriptViewController: UITableViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let fromTop = scrollView.contentOffset.y + scrollView.bounds.height
        autoScrollEnabled = fromTop + 10 >= scrollView.contentSize.height
    }
}

// MARK: - RtkTranscriptStartedCell

private class RtkTranscriptStartedCell: UITableViewCell {
    static let reuseID = "RtkTranscriptStartedCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        let label = RtkUIUtility.createLabel(text: "Transcription started", alignment: .center)
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = DesignLibrary.shared.color.textColor.onBackground.shade600
        contentView.addSubview(label)
        let space = DesignLibrary.shared.space
        label.set(.sameLeadingTrailing(contentView, space.space3), .sameTopBottom(contentView, space.space3))
    }

    required init?(coder _: NSCoder) {
        nil
    }
}

// MARK: - RtkTranscriptGroupCell

private class RtkTranscriptGroupCell: UITableViewCell {
    static let reuseID = "RtkTranscriptGroupCell"

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private let nameLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        return label
    }()

    private let timeLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = DesignLibrary.shared.color.textColor.onBackground.shade600
        return label
    }()

    private let transcriptLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = DesignLibrary.shared.color.textColor.onBackground.shade800
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        let space = DesignLibrary.shared.space

        let headerStack = RtkUIUtility.createStackView(axis: .horizontal, spacing: space.space2)
        headerStack.alignment = .center
        headerStack.addArrangedSubview(nameLabel)
        headerStack.addArrangedSubview(timeLabel)

        let bodyStack = RtkUIUtility.createStackView(axis: .vertical, spacing: space.space1)
        bodyStack.addArrangedSubview(headerStack)
        bodyStack.addArrangedSubview(transcriptLabel)

        contentView.addSubview(bodyStack)
        bodyStack.set(
            .top(contentView, space.space2),
            .bottom(contentView, space.space2),
            .leading(contentView, space.space3),
            .trailing(contentView, space.space3),
        )
    }

    required init?(coder _: NSCoder) {
        nil
    }

    func configure(with group: TranscriptGroup) {
        nameLabel.text = group.name
        timeLabel.text = Self.timeFormatter.string(from: group.timestamp)
        transcriptLabel.text = group.transcript
    }
}
