//
//  SocketManager.swift
//  YesWay
//
//  Created by 孙昊 on 16/9/21.
//  Copyright © 2016年 sunhao. All rights reserved.
//

import UIKit

@objc protocol SocketManagerDelegate:NSObjectProtocol
{
    func socketDidConnectToHost(host: String, port: UInt16)
    func socketDidDisconnect()
    func socketDidReadData(data: NSData)
}

class SocketManager: NSObject,GCDAsyncSocketDelegate {
    
    static let shareSocketManager:SocketManager = SocketManager()
    
    private let socketDictionary = NSMutableDictionary()//端口号为key
    private let socketDelegateDictionary = NSMutableDictionary()//端口号为key,可以允许有多个业务等待的情况。
    private let cacheSendBusinessDataDictionary = NSMutableDictionary()//端口号为key，每个端口只缓存一个将要发送的数据（目前主要解决的是在未连接的状态变为连接成功的状态后，再发送数据的问题。）
    private var sendHeartbeatTimer:Timer?
    
    
    override init()
    {
        super.init()
        
        if(sendHeartbeatTimer == nil)
        {
            sendHeartbeatTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(onTimer(sender:)), userInfo: nil, repeats: true)
        }
    }
    func onTimer(sender:Timer)
    {
        if(sendHeartbeatTimer == sender)
        {
            
        }
    }
    func addDelegate(delegate:SocketManagerDelegate!,withHost host:String!,withPort port:UInt16!)
    {
        //判断有无对应端口号的接收业务队列，如没有则建立并将新业务添加至接收业务队列中
        if(socketDelegateDictionary.object(forKey: "\(port)") == nil)
        {
            let socketDelegates = NSMutableArray()
            socketDelegateDictionary.setObject(socketDelegates, forKey: "\(port)" as NSCopying)
        }
        let socketDelegates = socketDelegateDictionary.object(forKey: "\(port)") as! NSMutableArray
        
        if(socketDelegates.contains(delegate) == false)
        {
            socketDelegates.add(delegate)
        }
    }
    func removeDelegate(delegate:SocketManagerDelegate!)
    {
        for socketDelegates in socketDelegateDictionary.allValues {
            (socketDelegates as AnyObject).remove(delegate)
        }
    }
    
    func sendData(data:NSData?,withHost host:String!,withPort port:UInt16!)
    {
        //判断有无对应端口号的实例对象，如没有则建立并进行连接
        if(socketDictionary.object(forKey: "\(port)") == nil)
        {
            let newSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
            socketDictionary.setObject(newSocket, forKey: "\(port)" as NSCopying)
            
            do {
                try newSocket.connect(toHost: host, onPort: port!)
            } catch let error as NSError {
                // 发生了错误
                let socketDelegates = socketDelegateDictionary.object(forKey: "\(port)") as! NSMutableArray
                for socketDelegate in socketDelegates {
                    (socketDelegate as AnyObject).socketDidDisconnect()
                }
                
                print(error.localizedDescription)
            }
        }
        //如果该连接状态正常，则马上发送，如果未连接则将数据缓存等待连接成功后马上发送。
        if((socketDictionary.object(forKey: "\(port)") as AnyObject).isConnected == true)
        {
            (socketDictionary.object(forKey: "\(port)") as AnyObject).write(data! as Data, withTimeout: -1, tag: 0)
        }
        else
        {
            if(data != nil)
            {
                cacheSendBusinessDataDictionary.setObject(data!, forKey: "\(port)" as NSCopying)
            }
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16)
    {
        sock.readData(withTimeout: -1, tag: 0)
        
        //连接成功后检查缓存中是否有需要发送的数据
        let data = cacheSendBusinessDataDictionary.object(forKey: "\(sock.connectedPort)")
        if(data != nil)
        {
            sock.write((data as! NSData) as Data, withTimeout: -1, tag: 0)
        }
        
    }
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?)
    {
        sock.disconnect()
        do {
            try sock.connect(toHost: sock.connectedHost!, onPort: sock.connectedPort)
        } catch let error as NSError {
            // 发生了错误
            let socketDelegates = socketDelegateDictionary.object(forKey: "\(sock.connectedPort)") as! NSMutableArray
            for socketDelegate in socketDelegates {
                (socketDelegate as AnyObject).socketDidDisconnect()
            }
            print(error.localizedDescription)
        }
    }
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int)
    {
        let socketDelegates = socketDelegateDictionary.object(forKey: "\(sock.connectedPort)") as! NSMutableArray
        for socketDelegate in socketDelegates
        {
            (socketDelegate as AnyObject).socketDidRead(data as Data!)
        }
        sock.readData(withTimeout: -1, tag: 0)
    }
}
