//
//  IntervalDetailsVC.swift
//  Glaucare
//
//  Created by Constantine Likhachov on 30.07.2020.
//  Copyright © 2020 APP3null. All rights reserved.
//

import UIKit

class IntervalDetailsVC: BaseViewController, MVVMViewController, BaseTableViewProtocol {

    var viewModel: IntervalDetailsVMProtocol!

    private let tableView = BaseTableView()

    override func updateLargeStyle() {
        super.updateLargeStyle()
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.tableViewDelegate = self
    }

    private func setupUI() {
        setupNavigationTitle(title: viewModel.interval.title)

        addTableView(tableView)
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = 200
        tableView.register(IntervalDetailsCell.self, forCellReuseIdentifier: IntervalDetailsCell.cellIdentifier)

        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: navigationView.bottomAnchor, constant: 5).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    //Navigation
    override func leftButtonPressed() {
        viewModel.dismiss()
    }

    override func rightButtonPressed() {
        let indexPaths = tableView.getAllIndexes()
        viewModel.speakButtonPressed(indexPaths: indexPaths)
    }
}

extension IntervalDetailsVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: IntervalDetailsCell.cellIdentifier, for: indexPath) as? IntervalDetailsCell  else {
            fatalError("No cell available")
        }
        let item = viewModel.item(at: indexPath)
        cell.config(for: item, interval: viewModel.interval, isLarge: largeStyle)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectRow(at: indexPath.row)
    }

    func setHighlight(indexPath: IndexPath, highlight: Bool) {
        if highlight {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension IntervalDetailsVC: TableViewDelegate {
    func scrollToTop() {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }

    func setHighlightCell(for speechData: SpeechData, highlight: Bool) {
        guard let indexPath = speechData.indexPath else { fatalError() }
        setHighlight(indexPath: indexPath, highlight: highlight)
    }
}
