//
//  ViewController.swift
//  FMDBTestDemo
//
//  Created by apple on 2017/6/6.
//  Copyright © 2017年 XinGuang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var dbPath:String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = documentPath.appendingPathComponent("fmdbUser.db")
        
        dbPath = path;
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func CreateTable(_ sender: UIButton) {
        print("\(#function)")

        
        guard let dbPath = self.dbPath else{
            return;
        }
            
        let db = FMDatabase(path: dbPath)
            
        if(db.open()){
                
            let sql = "CREATE TABLE 'User' ('id' INTEGER PRIMARY KEY AUTOINCREMENT  NOT NULL , 'name' VARCHAR(30), 'password' VARCHAR(30))"
            let res = db.executeUpdate(sql, withArgumentsIn: [])
                
            if !res{
                print("create database error!")
            }else{
                print("success to create database")
            }
            
            db.close()
        }else{
            print("open database error!")
        }
    }
    
    var id = 1
    
    @IBAction func InsertData(_ sender: UIButton) {
        print("\(#function)")
        
        guard let dbPath = self.dbPath else{
            return;
        }
        
        let db = FMDatabase(path: dbPath)
        
        if(db.open()){
            let sql = "insert into user (name , password) values(?,?)"
            
            let name = String.init(format: "yufeng_%d", id)
            
            id = id + 1
            
            let res = db.executeUpdate(sql,withArgumentsIn: [name, "boy"])
            
            if !res{
                print("error to insert data");
            }else{
                print("successed to insert data");
            }
            db.close();
        }
        
    }
    
    @IBAction func QueryData(_ sender: UIButton) {
        print("\(#function)")
        
        guard let dbPath = self.dbPath else{
            return;
        }
        
        let db = FMDatabase(path: dbPath)
        
        if(db.open()){
            let sql = "select * from user"
            
            let rs = db.executeQuery(sql, withArgumentsIn: [])
            
            while (rs?.next())! {
                let userId = rs?.int(forColumn: "id")
                let name = rs?.string(forColumn: "name")
                let pass = rs?.string(forColumn: "password")
                print("user id = \(String(describing: userId)), name = \(String(describing: name)), pass = \(String(describing: pass))")
            }
            db.close();
        }
    }
    
    @IBAction func ClearAll(_ sender: UIButton) {
        guard let dbPath = self.dbPath else{
            return;
        }
        
        let db = FMDatabase(path: dbPath)
        
        if(db.open()){
            let sql = "delete from user"
            let res = db.executeUpdate(sql, withArgumentsIn: [])
            if !res{
                print("error to delete db data")
            }else{
                print("successed to deleta db data")
            }
        
        }
        db.close()
        
    }
    
    @IBAction func multithread(_ sender: UIButton) {
        
        guard let dbPath = self.dbPath else{
            return;
        }
        
        let queue = FMDatabaseQueue.init(path: dbPath)
        let q1 = DispatchQueue.init(label: "queue1")
        let q2 = DispatchQueue.init(label: "queue2")
        
        q1.async {
            for i in 0..<100{
                queue.inDatabase{ db in
                    let sql = "insert into user (name, password) values(?, ?) "
                    let name = String.init(format: "queue111 %d", i)
                    let res = db.executeUpdate(sql, withArgumentsIn: [name,"boy"])
                    if !res{
                        print("error to add db data: \(name)")
                    }else{
                        print("success to add db data: \(name)")
                    }
                
                }
            
            }
        }
        
        q2.async {
            for i in 0..<100{
                queue.inDatabase{ db in
                    let sql = "insert into user (name, password) values(?, ?) "
                    let name = String.init(format: "queue222 %d", i)
                    let res = db.executeUpdate(sql, withArgumentsIn: [name,"boy"])
                    if !res{
                        print("error to add db data: \(name)")
                    }else{
                        print("success to add db data: \(name)")
                    }
                    
                }
                
            }
        }
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

