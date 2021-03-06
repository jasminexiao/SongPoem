//
//  gamemViewController.swift
//  诵诗
//
//  Created by yuannnn on 2017/7/30.
//  Copyright © 2017年 mac. All rights reserved.
//

import Foundation

import UIKit

import Alamofire

extension String {
    //返回第一次出现的指定子字符串在此字符串中的索引
    func startPositionOf(sub:String)->Int {
        var pos = -1
        if let range = range(of:sub) {
            if !range.isEmpty {
                pos = characters.distance(from:startIndex, to:range.lowerBound)
            }
        }
        return pos
    }
    func endPositionOf(sub:String)->Int {
        var pos = -1
        if let range = range(of:sub) {
            if !range.isEmpty {
                pos = characters.distance(from:startIndex, to:range.upperBound)
            }
        }
        return pos
    }
}

class gamemViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var statusLabel: UITextView!
    //数据库
    static var db: OpaquePointer? = nil
    
    //sqlite3_stmt指针
    static var stmt:OpaquePointer? = nil
    
    //填入诗句
    var fillIn: String?
    let inputText = UITextField()
    var addition = 0
    
    //参考位置
    var locate: CGFloat = 0.0
    
    //诗句摆放位置
    static let width = UIScreen.main.bounds.width
    let positionX = [[(width/2) + 30, (width/2) - 15], [(width/2) + 50, width/2, (width/2) - 50], [(width/2) + 90, (width/2) + 30, (width/2) - 30, (width/2) - 90]]
    
    //诗歌label
    var poemlabel = UILabel()
    
    //填空诗句符号
    let blankFrame = "︻\r\r\r\r\r\r\r︼"
    
    //检验按钮
    let checkButton = UIButton()
    
    //是否可以进入下一题
    var nexton = false
    
    var signOfSuccessDidAppear = false
    
//    let gameTitleArr:[String] = ["花","月","春","风","夜","人","山","云","酒"]
    
    var timer:Timer!
    var sec:Int = 0
    var localPlayer:String = ""
    @IBOutlet weak var gameTitle: UITextView!
    @IBOutlet weak var img1: UIImageView!//右边
    @IBOutlet weak var img2: UIImageView!//左边
    @IBOutlet weak var topPlayerLabel: UILabel!
    @IBOutlet weak var bottomPlayerLabel: UILabel!
    @IBOutlet weak var status2Label: UILabel!//youbian
    @IBOutlet weak var status1Label: UILabel!//ZUOBIAN
    @IBOutlet weak var head1: CircleProgressView!
    @IBOutlet weak var head2: CircleProgressView!
    
    let nf = NumberFormatter()
    
//    var game: Game!
//    var gameState = GameState()
//    var actions: [Action] = []
//    var player_head:Int = 1
    
    @IBAction func test(_ sender: Any) {
        let alert = UIAlertController.init(title: "提示", message: "确认退出后将删除本局游戏，同时扣除您相应积分", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction.init(title: "确认", style: .default, handler: {action in
            self.remForAll()
            self.overgame("平局")
            Alamofire.request("http://101.132.142.238/test/HelloWorld?order=4&name=\(self.localPlayer)", method: .get).responseString { response in
                let str = response.result.value!
                var dict = self.convertToDictionary(text: str)!
                //print(dict)
                self.statusLabel.text = "回答正确"
                self.status1Label.text = String(describing: dict["score1"]!)
                self.status2Label.text = String(describing: dict["score2"]!)
            }
            
            let gameleadView = UIStoryboard(name:"Main",bundle:nil).instantiateViewController(withIdentifier: "entranceView")
            self.present(gameleadView, animated: true, completion:nil)
//            self.gameState.status = .finished(results: [0:Result.tie, 1:Result.tie])
            
//            self.//updateView()
//            self.navigationController?.popViewController(animated: true)
        }))//删除游戏数据
        self.present(alert, animated: true) {
            
        }
    }
    
    func remForAll() {
        self.inputText.isHidden = true
        self.checkButton.isHidden = true
        self.poemlabel.isHidden = true
        self.img1.isHidden = true
        self.img2.isHidden = true
        self.topPlayerLabel.isHidden = true
        self.bottomPlayerLabel.isHidden = true
        self.status2Label.isHidden = true
        self.status1Label.isHidden = true
        self.head1.isHidden = true
        self.head2.isHidden = true
        self.statusLabel.isHidden = true
    }
    //产生随机题号
//    func blankID1(lineLimit: Int) -> Int{
//        let id = arc4random_uniform(UInt32(gameTitleArr.count))
//
//        return Int(id) >= lineLimit ? (lineLimit - 1) : Int(id)
//    }

//    var currentPlayerIsActive: Bool {
////        guard let index = self.gameState.currentPlayerIndex else { return false }
////        return self.game.localPlayerIdentifier == self.game.players[index].identifier
//    }
    
    var currentPlayerIndex: Int {
        return 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        let play = defaults.integer(forKey: "players")
        if (play==1){
            self.localPlayer="player1"
            self.topPlayerLabel.text = "对方玩家"
            self.bottomPlayerLabel.text = "本机玩家"
        }
        else if(play==2){
            self.localPlayer="player2"
            self.topPlayerLabel.text = "本机玩家"
            self.bottomPlayerLabel.text = "对方玩家"
        }
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(handleGameEvent),
//                                               name: GameNotificationName,
//                                               object: nil)
        timer = Timer.scheduledTimer(timeInterval: 1,target:self,selector:#selector(gamemViewController.changeplayer),userInfo:nil,repeats:true)
        
        nf.numberStyle = NumberFormatter.Style.decimal
        nf.maximumFractionDigits = 2
        self.head1.isHidden=true
        self.head2.isHidden=true
        
        self.self.head1.clockwise = true
        self.self.head1.progress = Double(100)
        self.self.head2.clockwise = true
        self.self.head2.progress = Double(100)
        
        let leftBarBtn = UIBarButtonItem(title: "", style: .plain, target: self,
                                         action: #selector(query))
        leftBarBtn.image = UIImage(named: "退")
        
        //用于消除左边空隙，要不然按钮顶不到最前面
//        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil,
//                                     action: nil)
//        spacer.width = -10;
        
//        self.navigationItem.leftBarButtonItems = leftBarBtn
        self.navigationItem.leftBarButtonItem = leftBarBtn
        self.navigationController?.isNavigationBarHidden = true
        
        
        initinputText()
        initLabel()
        
        initTitle()
//        operateQuery(key: "花")
        
    }
    
    func query(){
        let alert = UIAlertController.init(title: "提示", message: "确认退出后将删除本局游戏，同时扣除您相应积分", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction.init(title: "确认", style: .default, handler: {action in
//            self.gameState.status = .finished(results: [0:Result.tie, 1:Result.tie])
            self.navigationController?.popViewController(animated: true)
        }))//删除游戏数据
        self.present(alert, animated: true) {
            
        }
    }
    
    func operateQuery(key: String?) -> String? {
        gamemViewController.openDB()
//        let operation = "CREATE VIEW testView AS SELECT * FROM s_poem WHERE s_poem.poem LIKE '%\(key)%';"
//        //print(operation)
//        
//        if( sqlite3_exec(gamemViewController.db, operation.cString(using: .utf8), nil, nil, nil) != SQLITE_OK ){
//            //print(String.init(cString: sqlite3_errmsg(singleViewController.db)))
////            return
//        }
        
        if (key == nil) {
            return nil
        }
        let query = "SELECT poem FROM s_poem WHERE s_poem.poem LIKE '%\(key!)%';"
        //编译
        if sqlite3_prepare_v2(singleViewController.db, query.cString(using: .utf8), -1, &singleViewController.stmt, nil) != SQLITE_OK {
            sqlite3_finalize(singleViewController.stmt)
            if (sqlite3_errmsg(singleViewController.db)) != nil {
                let msg = "SQLiteDB - failed to prepare SQL:\(query);"
                //print(msg)
                //print(String.init(cString: sqlite3_errmsg(singleViewController.db)))
            }
            sqlite3_close(singleViewController.db)
        }
        while sqlite3_step(singleViewController.stmt) == SQLITE_ROW {
            
            if let temp = UnsafePointer(sqlite3_column_text(singleViewController.stmt, Int32(0))){
                let sentence = String.init(cString: temp)
                return(sentence)
            }
            
        }
        return nil
    }
    
    func initTitle() {
        gameTitle.font = UIFont(name: "FZQingKeBenYueSongS-R-GB", size: 50)
        gameTitle.translatesAutoresizingMaskIntoConstraints = false
        gameTitle.textAlignment = .center
        gameTitle.textColor = UIColor(red: 31/255, green: 89/255, blue: 107/255, alpha: 1)
        Alamofire.request("http://101.132.142.238/test/HelloWorld?order=100&name=\(localPlayer)", method: .get).responseString { response in
            //print("Success: \(response.result.isSuccess)")
            let str = response.result.value!
            let dict = self.convertToDictionary(text: str)
            //print(dict)
            //print (dict?["title"] as! String)
            self.gameTitle.text = dict?["title"] as! String
        }
    }
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                //print(error.localizedDescription)
            }
        }
        return nil
    }
    func initLabel() {
        //step
        operateQuery()
//        if (sqlite3_step(singleViewController.stmt) == SQLITE_ROW) {
        
//            //诗句数组
//            var lines = [String]()
//            
//            //从数据库中读出的诗句
//            var sentence: String
//            
//            for i in 3...6{
//                //读
//                if let temp = UnsafePointer(sqlite3_column_text(singleViewController.stmt, Int32(i))){
//                    sentence = String.init(cString: temp)
//                    if sentence.characters.count >= 2{
//                        lines.append(sentence)
//                    } else{
//                        break
//                    }
//                }
//            }
            //输入框
            let line = UILabel()
            line.font = UIFont(name: "FZQingKeBenYueSongS-R-GB", size: 28)
            line.numberOfLines = 0
            line.translatesAutoresizingMaskIntoConstraints = false
            self.poemlabel = line
            line.textAlignment = .center
            line.textColor = UIColor(red: 31/255, green: 89/255, blue: 107/255, alpha: 1)
            self.view.addSubview(line)
            line.text = blankFrame
            
            //                blank = i
            line.isUserInteractionEnabled = true
            
            //点击空label弹出键盘
            let tapGr = UITapGestureRecognizer(target: self, action: #selector(keyboardAppear(tap:)))
            line.addGestureRecognizer(tapGr)
            
            //加入输入框
            self.view.addSubview(self.inputText)
            addConstraints(line: self.inputText)
            
            //加入检验按钮
        initcheckButton()
            
            addConstraints(line: line)
//        }
        
    }
    
    //点击屏幕收起键盘
    func keyboardDisappear(tap: UITapGestureRecognizer){
        if nexton {
            return
        }
        
        
        
        self.inputText.resignFirstResponder()
        self.inputText.isHidden = true
        if(self.inputText.text == String()){
            self.poemlabel.text = blankFrame
        } else{
            self.poemlabel.text = self.inputText.text
        }
    }
    
    func initinputText(){
        self.inputText.translatesAutoresizingMaskIntoConstraints = false
        self.inputText.font = UIFont(name: "FZQingKeBenYueSongS-R-GB", size: 28)
        self.inputText.textAlignment = .center
        self.inputText.textColor = UIColor(red: 31/255, green: 89/255, blue: 107/255, alpha: 0)
        self.inputText.delegate = self as UITextFieldDelegate
        self.inputText.returnKeyType = UIReturnKeyType.done
        self.inputText.isHidden = true
        self.inputText.tintColor = UIColor(red: 31/255, green: 89/255, blue: 107/255, alpha: 0)
        //监听输入变化
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChange(notification:)), name: .UITextFieldTextDidChange, object: self.inputText)
    }
    
    @objc private func textFieldDidChange(notification: NSNotification){
        let textField = notification.object as! UITextField
        self.checkButton.setBackgroundImage(UIImage(named: "检验.png"), for: UIControlState.normal)
        if textField.text != blankFrame{
            
            self.poemlabel.text = textField.text
        }
        
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        fillIn = textField.text
        if(fillIn == String()){
            self.poemlabel.text = blankFrame
            self.checkButton.isUserInteractionEnabled = false
        } else{
            self.poemlabel.text = fillIn
            self.checkButton.setBackgroundImage(UIImage(named: "检验.png"), for: UIControlState.normal)
            self.checkButton.isUserInteractionEnabled = true
        }
        textField.isHidden = true
        return true
    }
    
    //点击label弹出键盘
    func keyboardAppear(tap: UITapGestureRecognizer){
        self.inputText.isHidden = false
        self.poemlabel.text = String()
        self.inputText.becomeFirstResponder()
        self.checkButton.setBackgroundImage(UIImage(named: "检验.png"), for: UIControlState.normal)
    }
    
    static func openDB(){
        //打开数据库
        let path = Bundle.main.path(forResource: "poemsentence", ofType: "db")
        let error = sqlite3_open_v2(path?.cString(using: .utf8), &singleViewController.db, SQLITE_OPEN_READWRITE, nil)
        
        //数据库打开失败
        if  error != SQLITE_OK {
            //print("数据库打开失败")
            sqlite3_close(singleViewController.db)
            //print(path!)
        }
        
    }
    
    func operateQuery(){
        
        var level = UserDefaults.standard.integer(forKey: "level") == 0 ? 1 : UserDefaults.standard.integer(forKey: "level")
        if((level/10+1) != UserDefaults.standard.integer(forKey: "currentLevel")){
            level = (UserDefaults.standard.integer(forKey: "currentLevel")-1)*10+1+addition
//            levelNum = level
        }
        
        
        //查询语句
        let sql = "SELECT * FROM s_poem WHERE ID = \(level);"
        
        //编译
        if sqlite3_prepare_v2(singleViewController.db, sql.cString(using: .utf8), -1, &singleViewController.stmt, nil) != SQLITE_OK {
            sqlite3_finalize(singleViewController.stmt)
            if (sqlite3_errmsg(singleViewController.db)) != nil {
                let msg = "SQLiteDB - failed to prepare SQL:\(sql)"
                //print(msg)
                //print(String.init(cString: sqlite3_errmsg(singleViewController.db)))
            }
            sqlite3_close(singleViewController.db)
        }
        //        //print(Int(sqlite3_column_int(singleViewController.stmt, 7)))
    }
    
    func initcheckButton(){
        self.view.addSubview(self.checkButton)
        
        self.checkButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.checkButton.superview!.addConstraint(NSLayoutConstraint(item: self.checkButton, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.poemlabel, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 4))
        
        self.checkButton.superview!.addConstraint(NSLayoutConstraint(item: self.checkButton, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.poemlabel, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: -1 ))
        
        self.checkButton.addConstraint(NSLayoutConstraint(item: self.checkButton, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: 48))
        
        self.checkButton.addConstraint(NSLayoutConstraint(item: self.checkButton, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: 48))
        
        self.checkButton.setBackgroundImage(UIImage(named: "检验.png"), for: UIControlState.normal)
        
        self.checkButton.addTarget(self, action: #selector(checkIfRight), for: .touchUpInside)
        
        self.checkButton.isUserInteractionEnabled = true
        
    }
    
    //比较填入诗句是否正确
    func checkIfRight(){
        
        fillIn = self.inputText.text
        if fillIn == nil {
            self.checkButton.setBackgroundImage(UIImage(named: "错误.png"), for: UIControlState.normal)
            return
        }
//        for po in self.gameState.poemRight {//首先要判断所填的诗句填过没有
//            if po=="" {
//                continue
//            }
//            if po.contains(fillIn!)||fillIn!.contains(po) {//已经填过 当作错误处理
//                self.checkButton.setBackgroundImage(UIImage(named: "错误.png"), for: UIControlState.normal)
//                return
//            }
//        }
        //不包含当前题目的字当作错误处理
        if !(fillIn!.contains(gameTitle.text)) {
            self.checkButton.setBackgroundImage(UIImage(named: "错误.png"), for: UIControlState.normal)
            return
        }
        
        let blank: String? = operateQuery(key: fillIn)
        
        var judg = false
        if blank != nil  {//判断输入了完整的一句
            let startPosition = blank!.startPositionOf(sub: fillIn!)
            let endPosition = blank!.endPositionOf(sub: fillIn!)
            judg = true
            if startPosition != 0{
                if let indSubStart = blank!.index(blank!.startIndex, offsetBy: startPosition-1, limitedBy: blank!.endIndex){
                    if ("\u{4E00}" <= blank!.characters[indSubStart]  && blank![indSubStart] <= "\u{9FA5}") {
                        judg = false
                    }
                    
                }
            }
            if let indSubEnd = blank!.index(blank!.startIndex, offsetBy: endPosition, limitedBy: blank!.endIndex){
                if ("\u{4E00}" <= blank![indSubEnd]  && blank![indSubEnd] <= "\u{9FA5}") {
                    judg = false
                }
                
            }
//            if let indSubStart = blank!.index(blank!.startIndex, offsetBy: startPosition-1, limitedBy: blank!.endIndex){
//                if ("\u{4E00}" <= blank!.characters[indSubStart]  && blank![indSubStart] <= "\u{9FA5}") {
//                    judg = false
//                }
//                else if let indSubEnd = blank!.index(blank!.startIndex, offsetBy: endPosition, limitedBy: blank!.endIndex){
//                    if ("\u{4E00}" <= blank![indSubEnd]  && blank![indSubEnd] <= "\u{9FA5}") {
//                        judg = false
//                    }
//                    
//                }
//                
//            }
//            if let indSubEnd = blank!.index(blank!.startIndex, offsetBy: endPosition, limitedBy: blank!.endIndex){
//                if ("\u{4E00}" <= blank![indSubEnd]  && blank![indSubEnd] <= "\u{9FA5}") {
//                    judg = false
//                }
//            }
            
//            else if ("\u{4E00}" <= blank![indSubEnd]  && blank![indSubEnd] <= "\u{9FA5}") {
//                judg = false
//            }
//            else {//两边都是标点
//                judg = true
//            }
        }
        
        if judg == true  {//回答对了以后首先要把时间清空成0
            sec = -1
            self.checkButton.setBackgroundImage(UIImage(named: "正确.png"), for: UIControlState.normal)
//            self.gameState.currPoemRight += 1
//            self.gameState.poemRight[self.gameState.currPoemRight] = fillIn!
//            self.poemlabel.text = blank
//            self.poemlabel.text = "zhengquela"
//            self.gameState.status = .turnRight
//            self.gameState.playerScore[currentPlayerIndex] += 1
//            self.//updateView()
//            let time: TimeInterval = 3.0
            
//            var dict:Dictionary<String,Any> = Dictionary()
            Alamofire.request("http://101.132.142.238/test/HelloWorld?order=3&name=\(self.localPlayer)", method: .get).responseString { response in
                let str = response.result.value!
                var dict = self.convertToDictionary(text: str)!
                //print(dict)
                self.statusLabel.text = "回答正确"
                self.status1Label.text = String(describing: dict["score1"]!)
                self.status2Label.text = String(describing: dict["score2"]!)
            }
            
            
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
//                self.sec = 0
//                self.switchToNextPoem()
//            }
            return
            
            
        } else{
            self.checkButton.setBackgroundImage(UIImage(named: "错误.png"), for: UIControlState.normal)
//            switchToNextPoem()//回答错误也要进入下一个人
            return
        }
        
        
        
    }

    //切换到下一玩家或者完成
    func switchToNextPoem(){//需要记录填写正确的诗句，下一次不能填写相同的诗句
        var dict:Dictionary<String,Any> = Dictionary()
        Alamofire.request("http://101.132.142.238/test/HelloWorld?order=100&name=\(localPlayer)", method: .get).responseString { response in
            let str = response.result.value!
            dict = self.convertToDictionary(text: str)!
            //print(dict)
            self.inputText.text = String()
            
            if String(describing: dict["state"]!) == "turn1" || String(describing: dict["state"]!) == "turn2" {
                self.self.inputText.removeFromSuperview()
                self.self.checkButton.removeFromSuperview()
                self.self.poemlabel.removeFromSuperview()
                self.initLabel()
                self.initable()
            }
            else{
                self.remForAll()
            }
        }
        //还需要有判断，时间以内可以交无数次，时间到了只能提交
//            runAction()//完成了tocomplete 在函数里面如果有人得到十分才结束
        
    }

    func initable(){
        self.inputText.isUserInteractionEnabled = true
        self.inputText.isEnabled = true
        self.poemlabel.isUserInteractionEnabled = true
        self.checkButton.isUserInteractionEnabled = true
        self.checkButton.isEnabled = true
        self.poemlabel.isEnabled = true
    }


    func addConstraints(line: UIView){
        
        let positionX = self.positionX[0][1]
        locate = positionX
        //添加约束
        
        line.superview!.addConstraint(NSLayoutConstraint(item: line, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 170))
        
        line.superview!.addConstraint(NSLayoutConstraint(item: line, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: CGFloat(positionX) ))
        
        line.addConstraint(NSLayoutConstraint(item: line, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: 400))
        
        line.addConstraint(NSLayoutConstraint(item: line, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: 35))
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        self.game.start()
    }
//    func handleGameEvent(_ notification: Notification) {
//        if let action = notification.object as? Action {
//            self.actions.append(action)
////            self.gameState = action.applyTo(gameState: gameState)
//        }
////        self.//updateView()
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //分别放本地的头像
//        img1player0
//        img2
//        self.bottomPlayerLabel.text = self.game.players[0].displayName
//        self.topPlayerLabel.text = self.game.players[1].displayName
//        self.//updateView()
    }
    
    //当判断正确的时候触发
    @IBAction func runAction() {
//        guard currentPlayerIsActive else { return }
//        let gameSelection = 1
//        self.game.add(action: ChoiceAction(timeInterval: Date().timeIntervalSince1970))
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func changeplayer() {
        var dict:Dictionary<String,Any> = Dictionary()
        Alamofire.request("http://101.132.142.238/test/HelloWorld?order=100&name=\(localPlayer)", method: .get).responseString { response in
            let str = response.result.value!
            dict = self.convertToDictionary(text: str)!
            //print(dict)
            
            switch String(describing: dict["state"]!) {
            case "turn1":
                do {
                    self.status1Label.text = String(describing: dict["score1"]!)
                    self.status2Label.text = String(describing: dict["score2"]!)
                    self.head1.isHidden=false;
                    self.head2.isHidden=true;
                    DispatchQueue.main.async(execute: {
                        self.head1.progress = Double(20-Double(String(describing: dict["time"]!))!)/Double(20)
                    })
                    if (self.localPlayer=="player1"){
                        self.poemlabel.isEnabled = true
                        self.inputText.isEnabled = true
                        self.inputText.isUserInteractionEnabled = true
                        self.poemlabel.isUserInteractionEnabled = true
                        self.checkButton.isEnabled = true
                        self.statusLabel.text = "我方作答"
                    }
                    else{
                        self.inputText.text=""
                        self.poemlabel.text=""
                        self.checkButton.setBackgroundImage(UIImage(named: "检验.png"), for: UIControlState.normal)
                        self.poemlabel.isEnabled = false
                        self.inputText.isEnabled = false
                        self.inputText.isUserInteractionEnabled = false
                        self.poemlabel.isUserInteractionEnabled = false
                        self.checkButton.isEnabled = false
                        self.statusLabel.text = "对方作答"
                    }
                }
            case "turn2":
                do {
                    self.status1Label.text = String(describing: dict["score1"]!)
                    self.status2Label.text = String(describing: dict["score2"]!)
                    self.head1.isHidden=true;
                    self.head2.isHidden=false;
                    DispatchQueue.main.async(execute: {
                        self.self.head2.progress = Double(20-Double(String(describing: dict["time"]!))!)/Double(20)
                    })
                    if (self.localPlayer=="player1"){
                        self.inputText.text=""
                        self.poemlabel.text=""
                        self.checkButton.setBackgroundImage(UIImage(named: "检验.png"), for: UIControlState.normal)
                        self.poemlabel.isEnabled = false
                        self.inputText.isEnabled = false
                        self.inputText.isUserInteractionEnabled = false
                        self.poemlabel.isUserInteractionEnabled = false
                        self.checkButton.isEnabled = false
                        self.statusLabel.text = "对方作答"
                    }
                    else{
                        self.poemlabel.isEnabled = true
                        self.inputText.isEnabled = true
                        self.inputText.isUserInteractionEnabled = true
                        self.poemlabel.isUserInteractionEnabled = true
                        self.checkButton.isEnabled = true
                        self.statusLabel.text = "我方作答"
                    }
                }
            case "tie":
                self.overgame("平局")
            case "":
                self.overgame("平局")
            case "win1":
                if (self.localPlayer=="player1"){
                    self.overgame("胜利")
                }
                else if (self.localPlayer=="player2"){
                    self.overgame("失败")
                }
            case "win2":
                if (self.localPlayer=="player2"){
                    self.overgame("胜利")
                }
                else if (self.localPlayer=="player1"){
                    self.overgame("失败")
                }
                
            default:
                return
        }
            if(Int(String(describing: dict["time"]!))==0||Int(String(describing: dict["time"]!))==20){
                self.switchToNextPoem()
            }
        }
        
//        //updateView()
        
//        var jud: Bool = currentPlayerIsActive
//        //如果本地玩家是玩家0的话 那么根据本地玩家的情况控制右边的头像
//        if self.game.players[currentPlayerIndex].identifier == self.game.players[0].identifier{
//            jud = !currentPlayerIsActive
//        }
//        if jud {//左边的头像亮 应该是玩家1
//            self.head1.isHidden=true;
//            self.head2.isHidden=false;
//            if sec != -1 {
//                sec += 1
//                self.self.head2.progress = Double(20-sec)/Double(20)
//            }
////            //print(self.self.head2.progress)
//            if sec == 20 {
////                player_head=2
//                self.head1.isHidden=false;
//                self.head2.isHidden=true;
//                sec = 0
//                switchToNextPoem()
//            }
//        }
//        else {//玩家0
//            self.head1.isHidden=false;
//            self.head2.isHidden=true;
//            if sec != -1 {
//                sec += 1
//                self.self.head1.progress = Double(20-sec)/Double(20)
//            }
//            if sec == 20 {
////                player_head=1
//                self.head1.isHidden=true;
//                self.head2.isHidden=false;
//                sec = 0
//                switchToNextPoem()
//            }
//        }
        //updateView()
    }
    
    func delay(_ delay:Double, closure: @escaping ()-> Void) {
        let delayTime = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: closure)
    }
    
    func overgame(_ state: String){
        
        self.remForAll()
        let signOfSuccess = UILabel()
        signOfSuccess.text = state
        
        signOfSuccess.font = UIFont(name: "FZQingKeBenYueSongS-R-GB", size: 28)
        signOfSuccess.numberOfLines = 0
        signOfSuccess.translatesAutoresizingMaskIntoConstraints = false
        signOfSuccess.textAlignment = .center
        signOfSuccess.textColor = UIColor(red: 114/255, green: 36/255, blue: 32/255, alpha: 1)
        self.view.addSubview(signOfSuccess)
        
        signOfSuccess.superview!.addConstraint(NSLayoutConstraint(item: signOfSuccess, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 160))
        
        signOfSuccess.superview!.addConstraint(NSLayoutConstraint(item: signOfSuccess, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: singleViewController.width / 2-10 ))
        
        signOfSuccess.addConstraint(NSLayoutConstraint(item: signOfSuccess, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: 400))
        
        signOfSuccess.addConstraint(NSLayoutConstraint(item: signOfSuccess, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: 35))
        
        signOfSuccessDidAppear = true
        let time: TimeInterval = 3.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
//    func updateView() {//更换图片在谁的头像上 以及最后的胜负 每十秒应该调用一次
////        self.status1Label.text = String(gameState.playerScore[0])
////        self.status1Label.text = String(gameState.playerScore[1])
//
//        self.poemlabel.isEnabled = currentPlayerIsActive
//        self.inputText.isEnabled = currentPlayerIsActive
//        self.inputText.isUserInteractionEnabled = currentPlayerIsActive
//        self.poemlabel.isUserInteractionEnabled = currentPlayerIsActive
//        self.checkButton.isEnabled = currentPlayerIsActive
//        switch self.gameState.status {
//        case .awaitingPlay:
//            self.statusLabel.text = currentPlayerIsActive ? "我方作答" : "对方作答"
//        case .turnComplete:
//            self.statusLabel.text = currentPlayerIsActive ? "我方作答" : "对方作答"
//        case .turnRight://显示正确的诗句！！！！！
//            self.statusLabel.text = "回答正确"
////            self.self.poemlabel.text = self.gameState.poemRight[self.gameState.currPoemRight]
////            self.status1Label.text = String(gameState.playerScore[0])
////            self.status2Label.text = String(gameState.playerScore[1])
//
//        case .finished(let results):
//
//                let signOfSuccess = UILabel()
//
//                guard let result = results[currentPlayerIndex] else { return }
//                switch result {
//                case .lost:
//                    signOfSuccess.text = "胜利"
//                case .won:
//                    signOfSuccess.text = "失败"
//                case .tie:
//                    signOfSuccess.text = "平局"
//                }
//
//                signOfSuccess.font = UIFont(name: "FZQingKeBenYueSongS-R-GB", size: 28)
//                signOfSuccess.numberOfLines = 0
//                signOfSuccess.translatesAutoresizingMaskIntoConstraints = false
//                signOfSuccess.textAlignment = .center
//                signOfSuccess.textColor = UIColor(red: 114/255, green: 36/255, blue: 32/255, alpha: 1)
//                self.view.addSubview(signOfSuccess)
//
//                signOfSuccess.superview!.addConstraint(NSLayoutConstraint(item: signOfSuccess, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 160))
//
//                signOfSuccess.superview!.addConstraint(NSLayoutConstraint(item: signOfSuccess, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1.0, constant: singleViewController.width / 2-10 ))
//
//                signOfSuccess.addConstraint(NSLayoutConstraint(item: signOfSuccess, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: 400))
//
//                signOfSuccess.addConstraint(NSLayoutConstraint(item: signOfSuccess, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0.0, constant: 35))
//
//                signOfSuccessDidAppear = true
//                let time: TimeInterval = 3.0
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
//                    self.navigationController?.popViewController(animated: true)
//                }
//
//        default:
//            self.statusLabel.text = ""
//        }
//
//    }
    
    
    
}
