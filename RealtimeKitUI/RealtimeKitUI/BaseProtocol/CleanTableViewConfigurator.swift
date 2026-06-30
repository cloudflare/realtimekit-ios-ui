//
//  CleanTableViewConfigurator.swift
//  RealtimeKitUI
//
//  Created by sudhir kumar on 16/02/23.
//

import UIKit

protocol BaseModel {
    func clean()
}

protocol ConfigureView {
    associatedtype Model: BaseModel
    var model: Model { get }
    func configure(model: Model)
}

protocol ViewConfigurator {
    func configure(view: UIView)
}

protocol CollectionTableConfiguratorProtocol: ViewConfigurator {
    var reuseIdentifier: String { get }
}

protocol Section {
    associatedtype Item: CollectionTableConfiguratorProtocol
    var items: [Item] { get set }
    func insert(_ item: Item)
}

class BaseConfiguratorSection<Item: CollectionTableConfiguratorProtocol>: Section {
    func insert(_ item: Item) {
        items.append(item)
    }

    var items: [Item] = .init()
}

class CollectionTableConfigurator: CollectionTableConfiguratorProtocol {
    var reuseIdentifier: String {
        fatalError("Must provide reuseIdentifier")
    }

    func configure(view _: UIView) {}
}

class CollectionTableSearchConfigurator: CollectionTableConfigurator, Searchable {
    func search(text _: String) -> Bool {
        fatalError(" \(type(of: self)) must Override 'func search(text: String) -> Bool' ")
    }
}

class TableItemConfigurator<Cell: TableViewCell, Model>: CollectionTableConfigurator where Cell.Model == Model {
    override var reuseIdentifier: String {
        Cell.reuseIdentifier
    }

    var model: Model

    init(model: Model) {
        self.model = model
    }

    override func configure(view: UIView) {
        guard let view_ = view as? Cell else {
            fatalError("\(type(of: view)) should confirm to \"\((any TableViewCell).self)\" ")
        }
        view_.configure(model: model)
    }

    deinit {
        self.model.clean()
    }
}

class TableItemSearchableConfigurator<Cell: TableViewCell, Model: Searchable>: CollectionTableSearchConfigurator where Cell.Model == Model {
    override var reuseIdentifier: String {
        Cell.reuseIdentifier
    }

    deinit {
        self.model.clean()
    }

    var model: Model

    init(model: Model) {
        self.model = model
    }

    override func search(text: String) -> Bool {
        model.search(text: text.lowercased())
    }

    override func configure(view: UIView) {
        guard let view_ = view as? Cell else {
            fatalError("\(type(of: view)) should confirm to \"\((any TableViewCell).self)\" ")
        }
        view_.configure(model: model)
    }
}

class DataSourceSearchStandard<S: Section>: DataSourceStandard<S> {
    let originalSections: [S]

    init(sections: [S]) {
        originalSections = sections
        super.init()
        self.sections = sections
    }

    func set(sections: [S]) {
        self.sections = sections
    }
}

class DataSourceStandard<S: Section> {
    var sections: [S] = .init()

    func numberOfRows(section: Int) -> Int {
        let sectionDTO = sections[section]
        return sectionDTO.items.count
    }

    func numberOfSections() -> Int {
        sections.count
    }

    func getItem(indexPath: IndexPath) -> S.Item? {
        if let section = getSection(section: indexPath.section) {
            return getItem(section: section, index: indexPath.item)
        }
        return nil
    }

    func replaceItem(at indexPath: IndexPath, with Object: S.Item) -> Bool {
        if var section = getSection(section: indexPath.section) {
            if section.items.count > indexPath.row {
                section.items[indexPath.row] = Object
                return true
            }
        }
        return false
    }

    func insertItem(at indexPath: IndexPath, with Object: S.Item) -> Bool {
        if var section = getSection(section: indexPath.section) {
            if section.items.count >= indexPath.row {
                if section.items.count == indexPath.row {
                    section.items.append(Object)
                } else {
                    section.items.insert(Object, at: indexPath.row)
                }
                return true
            }
        }
        return false
    }

    func removeSectionIfEmpty(indexPath: IndexPath) -> Bool {
        if let section = getSection(section: indexPath.section) {
            if section.items.count == 0 {
                sections.remove(at: indexPath.section)
                return true
            }
        }
        return false
    }

    func removeAll() {
        sections.removeAll()
    }

    func removeSection(_ section: Int) -> Bool {
        if let _ = getSection(section: section) {
            sections.remove(at: section)
            return true
        }
        return false
    }

    func removeItem(indexPath: IndexPath) -> Bool {
        if var section = getSection(section: indexPath.section) {
            if let _ = getItem(section: section, index: indexPath.item) {
                section.items.remove(at: indexPath.item)
                return true
            }
        }
        return false
    }

    func getSection(section: Int) -> S? {
        if sections.count > section {
            return sections[section]
        }
        return nil
    }

    func getElementsCount() -> Int {
        var count = 0
        var index = 0
        for _ in sections {
            count = count + numberOfRows(section: index)
            index = index + 1
        }
        return count
    }

    private func getItem(section: S, index: Int) -> S.Item? {
        if section.items.count > index {
            return section.items[index]
        }
        return nil
    }

    func iterate(start: IndexPath, iterator: (IndexPath, S.Item) -> Bool) {
        let sectionStart = start.section
        var itemStart = start.item
        let totalSection = sections.count
        var stopIterating = false

        for sectionIndex in sectionStart ..< totalSection {
            let section = sections[sectionIndex]
            let totalItemCount = section.items.count
            for itemIndex in itemStart ..< totalItemCount {
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)

                if iterator(indexPath, section.items[itemIndex]) {
                    stopIterating = true
                    break
                }
            }
            itemStart = 0
            if stopIterating {
                break
            }
        }
    }

    func iterate(iterator: (IndexPath, S.Item) -> Bool) {
        var sectionIndex = -1
        var stopIterating = false
        for section in sections {
            sectionIndex = sectionIndex + 1
            var itemIndex = -1
            for item in section.items {
                itemIndex = itemIndex + 1
                let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
                if iterator(indexPath, item) {
                    stopIterating = true
                    break
                }
            }
            if stopIterating {
                break
            }
        }
    }

    func configureCell(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let configurator = getItem(indexPath: indexPath) else {
            fatalError("parameter dataSource  have less number of cells")
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: configurator.reuseIdentifier, for: indexPath)
        configurator.configure(view: cell)
        return cell
    }
}

typealias TableViewCell = ConfigureView & ReusableObject & UITableViewCell

extension UITableView {
    func register(_ cell: (some UITableViewCell & ReusableObject).Type) {
        register(cell.self, forCellReuseIdentifier: cell.reuseIdentifier)
    }
}
