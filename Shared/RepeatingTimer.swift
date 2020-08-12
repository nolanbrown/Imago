//
//  RepeatingTimer.swift
//  Imago
//
//  Created by Nolan Brown on 7/27/20.
//  Copyright © 2020 Nolan Brown. All rights reserved.
//

/*
 Code by danielgalasko
 https://medium.com/over-engineering/a-background-repeating-timer-in-swift-412cecfd2ef9
 https://gist.github.com/danielgalasko/1da90276f23ea24cb3467c33d2c05768#file-repeatingtimer-swift
 */

import Foundation

class RepeatingTimer {

    let interval: DispatchTimeInterval
    let queue: DispatchQueue?

    init(secondsInterval: Int, queue: DispatchQueue? = nil) {
        self.queue = queue
        self.interval = DispatchTimeInterval.seconds(secondsInterval)
    }
    
    init(timeInterval: DispatchTimeInterval, queue: DispatchQueue? = nil) {
        self.queue = queue
        self.interval = timeInterval
    }
    
    private lazy var timer: DispatchSourceTimer = {
        let t = DispatchSource.makeTimerSource()//(queue: self.queue)
        t.schedule(deadline: .now() + self.interval, repeating: self.interval)
        t.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return t
    }()

    var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    deinit {
        timer.setEventHandler {}
        timer.cancel()
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        resume()
        eventHandler = nil
    }

    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }

    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
