//
//  AppDependencies.swift
//  JahPress
//
//  Created by Benjamin Ludwig on 17.12.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

struct AppDependencies {

    let globalLogger: Logger
    let shoutcastAPI: ShoutcastAPI
    let dataStore: DataStore

    func inject(into object: AnyObject) {
        if let dependencyInjectable = object as? AppDependencyInjectable {
            dependencyInjectable.dependencies = self
        }
    }
}

protocol AppDependencyInjectable: class {
    var dependencies: AppDependencies! { get set }
}
