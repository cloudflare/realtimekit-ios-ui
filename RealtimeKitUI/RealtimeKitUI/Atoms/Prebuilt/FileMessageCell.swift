import UIKit

class FileMessageCell: UITableViewCell {
    var downloadButtonAction: (() -> Void)?

    let grayBoxView: UIView = {
        let view = UIView()
        view.backgroundColor = rtkSharedTokenColor.background.shade900
        return view
    }()

    let fileTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = rtkSharedTokenColor.textColor.onBackground.shade1000
        label.numberOfLines = 2
        return label
    }()

    let nameLabel: RtkLabel = {
        let label = RtkUIUtility.createLabel(alignment: .left)
        label.font = UIFont.boldSystemFont(ofSize: 12)
        return label
    }()

    let fileTypeLabel: UILabel = {
        let label = UILabel()
        label.textColor = rtkSharedTokenColor.textColor.onBackground.shade700
        return label
    }()

    let fileSizeLabel: UILabel = {
        let label = UILabel()
        label.textColor = rtkSharedTokenColor.textColor.onBackground.shade700
        return label
    }()

    let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = rtkSharedTokenColor.textColor.onBackground.shade600
        return view
    }()

    let downloadButton: RtkButton = {
        let button = RtkButton(style: .iconOnly(icon: RtkImage(image: ImageProvider.image(named: "icon_down_arrow"))), rtkButtonState: .active)
        button.backgroundColor = rtkSharedTokenColor.background.shade800
        button.tintColor = .white
        // Set additional button properties if needed
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        fileTitleLabel.text = nil
        fileTypeLabel.text = nil
        fileSizeLabel.text = nil
        nameLabel.text = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Disable cell selection style and background color change
        selectionStyle = .none
        contentView.backgroundColor = .clear
    }

    @objc private func downloadButtonTapped() {
        // Call the download button action closure
        downloadButtonAction?()
    }

    private func setupViews() {
        downloadButton.setClickAction(click: { _ in
            self.downloadButtonTapped()
        })

        let tap = UITapGestureRecognizer(target: self, action: #selector(downloadButtonTapped))
        contentView.addGestureRecognizer(tap)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubview(nameLabel)
        nameLabel.set(.sameLeadingTrailing(contentView, rtkSharedTokenSpace.space3),
                      .top(contentView, rtkSharedTokenSpace.space2))
        // Add grayBoxView to the contentView
        contentView.addSubview(grayBoxView)

        // Set up constraints for grayBoxView
        grayBoxView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grayBoxView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            grayBoxView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            grayBoxView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            grayBoxView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        ])

        // Add subviews to grayBoxView
        grayBoxView.addSubview(fileTitleLabel)
        grayBoxView.addSubview(fileTypeLabel)
        grayBoxView.addSubview(fileSizeLabel)
        grayBoxView.addSubview(dividerView)
        grayBoxView.addSubview(downloadButton)
        grayBoxView.layer.cornerRadius = 10

        // Set up constraints for subviews within grayBoxView
        fileTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        fileTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            fileTitleLabel.topAnchor.constraint(equalTo: grayBoxView.topAnchor, constant: 10),
            fileTitleLabel.leadingAnchor.constraint(equalTo: grayBoxView.leadingAnchor, constant: 10),
            fileTitleLabel.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -10),

            downloadButton.centerYAnchor.constraint(equalTo: grayBoxView.centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: grayBoxView.trailingAnchor, constant: -10),
            downloadButton.widthAnchor.constraint(equalToConstant: 30),
            downloadButton.heightAnchor.constraint(equalToConstant: 30),

            fileTypeLabel.topAnchor.constraint(equalTo: fileTitleLabel.bottomAnchor, constant: 5),
            fileTypeLabel.leadingAnchor.constraint(equalTo: grayBoxView.leadingAnchor, constant: 10),
            fileTypeLabel.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor, constant: -5),
            fileTypeLabel.bottomAnchor.constraint(equalTo: grayBoxView.bottomAnchor, constant: -10),

            fileSizeLabel.topAnchor.constraint(equalTo: fileTitleLabel.bottomAnchor, constant: 5),
            fileSizeLabel.leadingAnchor.constraint(equalTo: dividerView.leadingAnchor, constant: 8),
            fileSizeLabel.trailingAnchor.constraint(equalTo: downloadButton.trailingAnchor, constant: -10),
            fileSizeLabel.bottomAnchor.constraint(equalTo: grayBoxView.bottomAnchor, constant: -10),

            dividerView.centerYAnchor.constraint(equalTo: fileTypeLabel.centerYAnchor, constant: 0),
            dividerView.leadingAnchor.constraint(equalTo: fileTypeLabel.trailingAnchor, constant: -8),
            dividerView.widthAnchor.constraint(equalToConstant: 1),
            dividerView.heightAnchor.constraint(equalToConstant: 12),
        ])

        contentView.layoutIfNeeded()
    }
}
