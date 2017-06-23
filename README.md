在swift项目中使用FMDB操作SQlite数据库

SQlite是一个轻量级的关系数据库，IOS只需要加入libsqlite3.dylib及头文件即可支持SQlite数据库，但是原生的 SQLite API 在使用上相当不友好，易用性不足，所以出现了很多基于SQLite API的封装库，FMDB就是其中比较简洁易用的代表。它是iOS平台的SQlite数据库框架，以OC的方式封装了SQlite的C语言API，使其更加简单易用。另外，FMDB 同时兼容 ARC 和非 ARC 工程，会自动根据工程配置来调整相关的内存管理代码。

优点是：

- 以OC方式封装SQlite的C语言API，使用方便
- 轻量级框架，使用灵活
- 线程安全

缺点是：

- 只能在ios开发的时候使用，实现跨平台操作的时候存在局限性。(腾讯开源了一个跨平台数据库框架WCDB https://github.com/Tencent/wcdb；还有大名鼎鼎的Realm跨平台移动数据库引擎)
- SQL语句采用字符串拼接方式，无法通过编译器检查，出错不易排查

安装方式：

Cocoapods或者手动导入，同时添加Sqlite3的依赖包，桥接文件

核心类：

- FMDatabase

  一个FMDatabase代表一个SQlite数据库，可用于各种SQL命令操作

  - executeStatements: 执行多条语句
  - executeQuery: 执行查询语句
  - executeUpdate: 执行除查询外其他操作，如create、insert、delete、update等

- FMDatabaseQueue

  在多个线程中执行查询或者更新，保证线程安全

  - inDatabase: 参数是一个闭包, 在闭包里面传入FMDatabase对象
  - inTransaction: 使用事物

- FMResultSet

  使用FMDatabase查询后的结果集，可以通过字段名称获取字段值

使用方法：

- 创建

  - 当指定路径的数据库文件不存在时，会自动创建。
  - 路径参数为空字符串，会在临时文件目录下创建这个数据库，数据库断开连接时，数据库文件被删除。
  - 路径参数为NULL，会建立一个在内存中的数据库，数据库断开连接时，数据库文件被删除

  ```
  //定义路径
  let documentPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last! as NSString
  let dbpath = documentPath.appendingPathComponent("fmdbUser.db")
  let db = FMDatabase(path: dbPath)
  //打开数据库
  if(db.open()){
    //some operation
    db.close()//关闭数据库
  }else{
    //error
  }
  ```

- 增删查改

  - 打开操作失败，可能是权限不足或者资源不足。通常打开完操作操作后，需要调用 close 方法来关闭数据库
  - 更新：executeUpdate，错误可以使用error参数API，除了select的所有操作基本都是使用executeUpdate

  ```
  let sql = "insert into user (name , password) values(?,?)"
  let res = db.executeUpdate(sql,withArgumentsIn: [name, "boy"])
  ```

  - 查询：executeQuery, 即使操作结果只有一行，也需要先调用 FMResultSet 的 next 方法。

  ```
  let sql = "select * from user"
  let rs = db.executeQuery(sql, withArgumentsIn: [])//FMResultSet
  while (rs?.next())! {
      let userId = rs?.int(forColumn: "id")
      let name = rs?.string(forColumn: "name")
      let pass = rs?.string(forColumn: "password")
      print("user id = \(String(describing: userId)), name = \(String(describing: name)), pass = \(String(describing: pass))")
  }
  db.close();
  ```

  FMDB 提供如下多个方法来获取不同类型的数据：

  ```
  intForColumn:
  longForColumn:
  longLongIntForColumn:
  boolForColumn:
  doubleForColumn:
  stringForColumn:
  dateForColumn:
  dataForColumn:
  dataNoCopyForColumn:
  UTF8StringForColumnIndex:
  objectForColumn:
  ```

  除了根据字段获取数据，还可以用对应的ForColumnIndex根据字段位置来获取

  通常情况下，并不需要关闭 FMResultSet，因为相关的数据库关闭时，FMResultSet 也会被自动关闭。

  数据参数可以使用标准SQL语句，用 ? 表示执行语句的参数，在具体方法中传入参数

- 多线程操作

  如果需要多线程操作数据库，不能在多个线程中共同一个 FMDatabase 对象并且在多个线程中同时使用，这个类本身不是线程安全的，这样使用会造成数据混乱等问题，正确的方法是使用FMDatabaseQueue来保证线程安全。首先用一个数据库文件地址来初使化 FMDatabaseQueue，然后就可以将一个闭包 (block) 传入 inDatabase 方法中（事务的话是inTransaction）。

  ```
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

  ```

  还有很多SQL操作和FMDB的API并没有提及到，需要平时多实践，另外相比CoreData和SQLite API，使用起来方便很多。