//
//  ChannelViewController.swift
//  IPMQuickstart-Swift
//
//  Created by Brent Schooley on 11/25/15.
//  Copyright © 2015 Twilio. All rights reserved.
//

import UIKit

class ChannelViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, TwilioIPMessagingClientDelegate {
    var client: TwilioIPMessagingClient?
    var channel: TMChannel?
    let channelName = "general"
    var messages: [TMMessage] = []
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardDidShow:"), name:UIKeyboardDidShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 66.0
        self.tableView.separatorStyle = .None
        
        IPMessagingService.sharedService.initializeClient("iphone") {
            self.client = IPMessagingService.sharedService.client
            self.client?.delegate = self
            
            self.joinOrCreateChannel()
        }
    }
    
    // MARK: - IPM Management
    func joinOrCreateChannel() {
        self.client?.channelsListWithCompletion(self.channelListRetrieved)
    }
    
    func channelListRetrieved(result: TMResultEnum, channels: TMChannels!) {
        if result == .Success {
            if let channel = channels.channelWithUniqueName(self.channelName) {
                self.channel = channel
                self.joinChannel()
            } else {
                channels.createChannelWithFriendlyName("General Channel", type: .Public, completion:self.channelCreated)
            }
        } else {
            print("Error listing channels")
        }
    }
    
    func channelCreated(result: TMResultEnum, channel: TMChannel!) {
        if result == .Success {
            self.channel = channel
            self.joinChannelAndSetUniqueName(self.channelName)
        } else {
            print("Error creating channel")
        }
    }
    
    func joinChannel() {
        self.channel?.joinWithCompletion() {
            (result) -> Void in
            if result != .Success {
                print("Error joining channel")
            }
        }
    }
    
    func joinChannelAndSetUniqueName(name: String) {
        self.channel?.joinWithCompletion() {
            (result) -> Void in
            if result == .Success {
                self.channel?.setUniqueName(name) {
                    (result) -> Void in
                    if result != .Success {
                        print("Error setting unique name")
                    }
                }
            } else {
                print("Error joining channel")
            }
        }
    }
    
    func loadMessages() {
        self.messages.removeAll()
        let messages = self.channel?.messages.allObjects()
        self.addMessages(messages!)
    }
    
    func addMessages(messages: [TMMessage]) {
        self.messages.appendContentsOf(messages)
        self.messages.sortInPlace { $1.timestamp > $0.timestamp }
        
        dispatch_async(dispatch_get_main_queue()) {
            () -> Void in
            self.tableView.reloadData()
            if self.messages.count > 0 {
                self.scrollToBottomMessage()
            }
        }
    }
    
    func scrollToBottomMessage() {
        if self.messages.count == 0 {
            return
        }
        
        let bottomMessageIndex = NSIndexPath(forRow: self.tableView.numberOfRowsInSection(0) - 1, inSection: 0)
        self.tableView.scrollToRowAtIndexPath(bottomMessageIndex, atScrollPosition: .Bottom, animated: true)
    }
    
    // MARK: - Memory
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.height
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardHeight!
            self.view.layoutIfNeeded()
        })
    }
    
    func keyboardDidShow(notification: NSNotification) {
        self.scrollToBottomMessage()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageTableViewCell", forIndexPath: indexPath) as! MessageTableViewCell
        
        let message = self.messages[indexPath.row]
        
        cell.nameLabel.text = message.author
        cell.bodyLabel.text = message.body
        cell.selectionStyle = .None
        
        return cell
    }
    
    @IBAction func sendButtonPressed(sender: AnyObject) {
        let message = self.channel?.messages.createMessageWithBody(self.messageTextField.text)
        
        if message?.body == "" {
            return
        }
        
        self.channel?.messages.sendMessage(message){
            (result) -> Void in
            if result != .Success {
                print("Error sending message...")
            }
        }
        self.messageTextField.text = ""
        self.messageTextField.resignFirstResponder()
    }
    
    func ipMessagingClient(client: TwilioIPMessagingClient!, channelHistoryLoaded channel: TMChannel!) {
        self.loadMessages()
    }
    
    // MARK: - Channel Delegate
    func ipMessagingClient(client: TwilioIPMessagingClient!, channel: TMChannel!, messageAdded message: TMMessage!) {
        self.addMessages([message])
    }
}