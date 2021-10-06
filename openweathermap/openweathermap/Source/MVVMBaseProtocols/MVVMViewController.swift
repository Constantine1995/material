//
//  MVVMViewControllerProtocol.swift
//  momswipe
//
//  Created by Iraklii Tavadze on 10/13/18.
//  Copyright © 2018 APP3null. All rights reserved.
//

protocol MVVMViewController: class {
    
    associatedtype ViewModelType
    
    var viewModel: ViewModelType! { get set }
    
}
