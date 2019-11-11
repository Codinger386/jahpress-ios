//
//  TabBarController.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 25.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, AppDependencyInjectable {
    var dependencies: AppDependencies!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers?.forEach { dependencies.inject(into: $0) }
    }
}
