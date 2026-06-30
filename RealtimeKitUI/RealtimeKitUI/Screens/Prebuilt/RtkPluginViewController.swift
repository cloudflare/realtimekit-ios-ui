//
//  RtkPluginViewController.swift
//  RealtimeKitUI
//
//  Created by Shaunak Jagtap on 24/01/23.
//

import Foundation
import RealtimeKit
import UIKit

public class RtkPluginViewController: UIViewController {
    // MARK: - Properties

    var plugins: [RtkPlugin] = []
    let pluginTableView = UITableView()

    public init(plugins: [RtkPlugin]) {
        self.plugins = plugins
        if plugins.count > 0 {
            pluginTableView.accessibilityIdentifier = "Plugins_List"
        }
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - View Life Cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        view.accessibilityIdentifier = "Plugins_Screen"
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Views

    private func setupViews() {
        // configure messageTableView
        pluginTableView.delegate = self
        pluginTableView.keyboardDismissMode = .onDrag
        pluginTableView.dataSource = self
        pluginTableView.register(PluginCell.self, forCellReuseIdentifier: "PluginCell")
        pluginTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pluginTableView)

        let leftButton = RtkControlBarButton(image: RtkImage(image: ImageProvider.image(named: "icon_cross")))
        leftButton.backgroundColor = navigationItem.backBarButtonItem?.tintColor
        leftButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        let customBarButtonItem = UIBarButtonItem(customView: leftButton)
        navigationItem.leftBarButtonItem = customBarButtonItem

        let label = RtkUIUtility.createLabel(text: "Plugins")
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = DesignLibrary.shared.color.textColor.onBackground.shade900
        navigationItem.titleView = label
        // add constraints
        let constraints = [
            pluginTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pluginTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pluginTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pluginTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: - Actions

    @objc func goBack() {
        dismiss(animated: true)
    }
}

extension RtkPluginViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        plugins.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PluginCell", for: indexPath) as? PluginCell {
            cell.set(plugin: plugins[indexPath.row], indexPath: indexPath)
            return cell
        }

        return UITableViewCell(frame: .zero)
    }

    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let plugin = plugins[indexPath.row]
        if plugin.isActive {
            plugin.deactivate()
        } else {
            plugin.activate()
        }
        goBack()
    }
}
