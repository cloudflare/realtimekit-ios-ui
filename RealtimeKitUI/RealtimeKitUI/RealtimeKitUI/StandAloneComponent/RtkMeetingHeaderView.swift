//
//  RtkMeetingHeaderView.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 14/07/23.
//

import RealtimeKit
import UIKit

open class RtkMeetingHeaderView: UIView {
    private let nextPreviousButtonView = NextPreviousButtonView()
    private var nextButtonClick: ((RtkControlBarButton) -> Void)?
    private var previousButtonClick: ((RtkControlBarButton) -> Void)?

    private let tokenTextColorToken = DesignLibrary.shared.color.textColor
    private let tokenSpace = DesignLibrary.shared.space
    private let backgroundColorValue = DesignLibrary.shared.color.background.shade900
    let containerView = UIView()

    public lazy var lblSubtitle: RtkParticipantCountView = {
        let label = RtkParticipantCountView(meeting: self.meeting)
        label.textAlignment = .left
        return label
    }()

    private lazy var clockView: RtkClockView = {
        let label = RtkClockView(meeting: self.meeting)
        label.textAlignment = .left
        return label
    }()

    private lazy var recordingView: RtkRecordingView = {
        let view = RtkRecordingView(meeting: self.meeting, title: "Rec", image: nil, appearance: AppTheme.shared.recordingViewAppearance)
        return view
    }()

    private let meeting: RealtimeKitClient

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setContentTop(offset: CGFloat) {
        containerView.get(.top)?.constant = offset
    }

    public init(meeting: RealtimeKitClient) {
        self.meeting = meeting
        super.init(frame: .zero)
        backgroundColor = backgroundColorValue
        createSubViews()
        nextPreviousButtonView.isHidden = true
    }

    private func createSubViews() {
        addSubview(containerView)
        containerView.set(.sameTopBottom(self, 0, .lessThanOrEqual))
        containerView.set(.sameLeadingTrailing(self, 0, .lessThanOrEqual))
        createSubview(containerView: containerView)
    }

    private func createSubview(containerView: UIView) {
        let stackView = RtkUIUtility.createStackView(axis: .vertical, spacing: 4)
        containerView.addSubview(stackView)

        let title = RtkMeetingTitleLabel(meeting: meeting)
        let stackViewSubTitle = RtkUIUtility.createStackView(axis: .horizontal, spacing: 4)
        stackViewSubTitle.addArrangedSubviews(lblSubtitle, clockView)
        stackView.addArrangedSubviews(title, stackViewSubTitle)
        containerView.addSubview(recordingView)

        let nextPreviousStackView = RtkUIUtility.createStackView(axis: .horizontal, spacing: tokenSpace.space2)
        containerView.addSubview(nextPreviousStackView)

        stackView.set(.leading(containerView, tokenSpace.space3),
                      .sameTopBottom(containerView, tokenSpace.space2))
        recordingView.set(.centerY(containerView),
                          .top(containerView, tokenSpace.space1, .greaterThanOrEqual),
                          .after(stackView, tokenSpace.space3))
        recordingView.get(.top)?.priority = .defaultLow
        nextPreviousStackView.set(.after(recordingView, tokenSpace.space3, .greaterThanOrEqual),
                                 .trailing(containerView, tokenSpace.space3),
                                 .centerY(containerView),
                                 .top(containerView, tokenSpace.space1, .greaterThanOrEqual))
        nextPreviousStackView.get(.top)?.priority = .defaultLow

        let cameraSwitchButton = RtkSwitchCameraButtonControlBar(meeting: meeting)
        cameraSwitchButton.backgroundColor = backgroundColor
        nextPreviousStackView.addArrangedSubviews(nextPreviousButtonView, cameraSwitchButton)

        nextPreviousButtonView.previousButton.addTarget(self, action: #selector(clickPrevious(button:)), for: .touchUpInside)
        nextPreviousButtonView.nextButton.addTarget(self, action: #selector(clickNext(button:)), for: .touchUpInside)
    }

    @objc private func clickPrevious(button: RtkControlBarButton) {
        button.showActivityIndicator()
        loadPreviousPage()
        previousButtonClick?(button)
    }

    @objc private func clickNext(button: RtkControlBarButton) {
        button.showActivityIndicator()
        loadNextPage()
        nextButtonClick?(button)
    }
}

public extension RtkMeetingHeaderView {
    // MARK: Public methods

    func refreshNextPreviousButtonState() {
        if meeting.meta.meetingType == RtkMeetingType.webinar {
            // For Hive Webinar we are not showing any pagination. Hence feature is disabled.
            return
        }

        let nextPagePossible = meeting.participants.canGoNextPage
        let prevPagePossible = meeting.participants.canGoPreviousPage

        if !nextPagePossible, !prevPagePossible {
            // No page view to be shown
            nextPreviousButtonView.isHidden = true
        } else {
            nextPreviousButtonView.isHidden = false

            nextPreviousButtonView.nextButton.isEnabled = nextPagePossible
            nextPreviousButtonView.previousButton.isEnabled = prevPagePossible
            nextPreviousButtonView.nextButton.hideActivityIndicator()
            nextPreviousButtonView.previousButton.hideActivityIndicator()
            setNextPreviousText(first: Int(meeting.participants.currentPageNumber), second: Int(meeting.participants.pageCount) - 1)
        }
    }

    func setClicks(nextButton: @escaping (RtkControlBarButton) -> Void, previousButton: @escaping (RtkControlBarButton) -> Void) {
        nextButtonClick = nextButton
        previousButtonClick = previousButton
    }
}

private extension RtkMeetingHeaderView {
    private func loadPreviousPage() {
        if meeting.participants.canGoPreviousPage == true {
            meeting.participants.setPage(pageNumber: meeting.participants.currentPageNumber - 1)
        }
    }

    private func loadNextPage() {
        if meeting.participants.canGoNextPage == true {
            meeting.participants.setPage(pageNumber: meeting.participants.currentPageNumber + 1)
        }
    }

    private func setNextPreviousText(first: Int, second: Int) {
        if first == 0 {
            nextPreviousButtonView.autoLayoutImageView.isHidden = false
            nextPreviousButtonView.autolayoutModeEnable = true
        } else {
            nextPreviousButtonView.autoLayoutImageView.isHidden = true
            nextPreviousButtonView.autolayoutModeEnable = false

            nextPreviousButtonView.setText(first: "\(first)", second: "\(second)")
        }
    }
}
