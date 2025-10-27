// Copyright (C) 2025 Toit Contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

// Base imports
import log
import gpio

class Rwcl0516:
  static WAIT-FOR-DETECTION-TASK-FLAG ::= "wait-for-detection"

  pin_/gpio.Pin := ?
  logger_/log.Logger := ?
  detected_/bool := ?
  tasks_/Map := ?
  callback-movement_/Lambda? := ?
  callback-clear_/Lambda? := ?
  as-task_/bool := ?

  constructor pin/any --as-task/bool=true --logger/log.Logger=log.default:
    logger_ = logger.with-name "rwcl0516"
    detected_ = false
    tasks_ = {:}
    callback-movement_ = null
    callback-clear_ = null
    if pin is int:
      pin_ = gpio.Pin pin --input  --pull-down
    if pin is gpio.Pin:
      pin_ = pin
    else:
      logger_.error "Unknown type passed to constructor."
      throw "Unknown type passed to constructor."
    as-task_ = as-task
    start-wait-for-detection_

  run-callbacks-as-tasks val/bool -> none:
    as-task_ = val

  set-callback --movement/Lambda?=null --clear/Lambda?=null -> none:
    if movement != null:
      callback-movement_ = movement
      logger_.info "Movement trigger callback set."
    if clear != null:
      callback-clear_ = clear
      logger_.info "Movement clear callback set."

  // Read Clears
  motion-detected -> bool:
    if detected_ == true:
      detected_ = false
      return true
    else:
      return false

  start-wait-for-detection_ -> none:
    tasks_[WAIT-FOR-DETECTION-TASK-FLAG] = task:: task-wait-for-detection_

  // Task to update the screen regardless of things going on. Intended to be run
  // as a task.  Will block if run directly.
  task-wait-for-detection_ -> none:
    logger_.info "task-wait-for-detection_: started." //--tags={"freq-ms" : sleep-duration.in-ms}
    while true:
      pin_.wait-for 1
      //logger_.info "Detected Movement ..."
      detected_ = true
      if callback-movement_ is Lambda:
        if as-task_:
          tasks_["callback-movement"] = task:: callback-movement_.call
        else:
          callback-movement_.call
      sleep --ms=100

      pin_.wait-for 0
      //logger_.info "Clear Movement ..."
      if callback-clear_ is Lambda:
        if as-task_:
          tasks_["callback-clear"] = task:: callback-clear_.call
        else:
          callback-clear_.call

      sleep --ms=50

  stop-callbacks -> none:
    tasks_.keys.do:
      if it != WAIT-FOR-DETECTION-TASK-FLAG:
        logger_.info "stop-all-tasks: stopped task." --tags={"task" : "$it", "was-cancelled" : it.is-cancelled }
        tasks_[it].cancel
