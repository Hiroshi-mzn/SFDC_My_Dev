////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    2019.06.17 cookpad課題「User API連携」
//
//    Title:Batch_GetUserInfo
//    ------------------------
//    Author:Hiroshi Mizuno
//    Create:2019.06.15
//
//    [API Status]
//    StatusCode    reason
//    200           OK
//    404           No User
//
//    [Sample JSON BODY]
//    {"id":1, "name":"Austin", "friends":[2,5]}
//
//    [range of user.id]
//    1-10
//
//    [Description]
//    ・1-10の範囲内のidが存在しない時のレスポンスは不明(404だと想定されるが)なのでuserのdeleteは行わない
//    ・StatusCode分かれば対象のレコードを削除できる + 主従関係なのでfriendsも削除される
//    ・friendsはAdd/reduceの変動を考慮し、Listをdelete/insertする
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class Batch_GetUserInfo implements Database.Batchable<Integer>, Database.AllowsCallouts {
        
    private integer StartNum;
    private integer EndNum;

    public Batch_GetUserInfo(Integer SN,Integer EN){
    
        //指定ない時はカスタム表示ラベルから取得
        if(SN == Null) StartNum  = integer.ValueOf(system.label.UserInfo_Batch_StartNum);
        else StartNum = SN;
        //指定ない時はカスタム表示ラベルから取得
        if(EN == Null) EndNum  = integer.ValueOf(system.label.UserInfo_Batch_EndNum);
        else EndNum = EN;
    
    }
        
    public Iterable<Integer> start(Database.BatchableContext BC){
                
        //存在する会員データのid最大値をscodeに加える(※≠処理件数 idが抜けてる場合を考慮)
        List<Integer> scope = new List<Integer>();
        for(Integer i = StartNum; i <= EndNum; i++){
            scope.add(i);
        }
        return scope;
    }
    
    public void execute(Database.BatchableContext BC, List<Integer> scope){
    
        System.debug('scope size: ' + scope.size());       
            
        //User更新データ格納リスト  
        List<user__c> usrLst = new List<user__c>();
        //friends削除データ格納リスト
        List<friends__c> delFrLst = new List<friends__c>();
        //friends更新データ格納リスト
        List<friends__c> frLst = new List<friends__c>();

          
        //APIは1User分を取得するものなので、ここでscope対象分回す
        for(Integer i : scope){
            try{
                HttpRequest req = new HttpRequest();       
                req.setMethod('GET');
                req.setEndpoint('http://fg-69c8cbcd.herokuapp.com/user/' + i);
            
                Http http = new Http();
                HttpResponse res = new HttpResponse();
                       
                res = http.send(req);
                Integer statusCode = res.getStatusCode();

                System.debug(LoggingLevel.INFO, 'STATUS:' + res.getStatus());
                System.debug(LoggingLevel.INFO, 'STATUS_CODE:' + res.getStatusCode());
                
                //Request is Not Success
                if(statusCode != 200) {
                    //ここでは何もしない
                //Request is Success
                }else{                    
                
                    String str = res.getbody();
                    //受け取ったレスポンス本体をパース
                    Json2Apex userdata = Json2Apex.parse(str);
                    System.debug('userdata:' + userdata); 
                    System.debug('userdata.friends:' + userdata.friends +' size:' + userdata.friends.size());

                    //Add List User__c                    
                    User__c Usr = new User__c();
                    Integer UsrId = Integer.ValueOf(userdata.id);
                    Usr.id__c = UsrId;
                    Usr.Name = userdata.name;
                    //取得したUserをリストに格納
                    usrLst.add(Usr);
                                        
                    //delete & insert friends__c
                                        
                    List<friends__c> delFr = [Select ID, from__c From Friends__c Where from__c =:UsrId];
                    
                    for(friends__c del:delFr){
                        delFrLst.add(del);
                    }
                
                    if(userdata.friends.size() > 0){
                                               
                        //取得したfriendsのリスト件数分をloop
                        for(Integer fi = 0; fi < userdata.friends.size(); fi++){                        
                    
                            friends__c frd = new friends__c();
                            frd.Name = UsrId + '->' + userdata.friends[fi];
                            frd.from__c = UsrId;
                            frd.to__c = userdata.friends[fi];                            
                            frd.External_key__c = UsrId + '-' + userdata.friends[fi]; //upsert用に外部ID設定
                            frd.User_Name__r = new user__c(id__c = UsrId);            //主オブジェクトの外部IDを指定
                            frd.friend_Name__r = new user__c(id__c = userdata.friends[fi]);            //主オブジェクトの外部IDを指定
                            //取得したfriendsをリストに格納
                            frLst.add(frd);                            
                        }
                    }                                      
                }
            }catch (Exception e) {        
                System.debug('Error:' + e.getMessage());          
            }    //try end
    
        }    //for loop end
        //リスト一括処理
        upsert usrLst Usr.id__c;
        delete delfrLst;
        upsert frLst frd.External_key__c;
    }
    
    public void finish(Database.BatchableContext BC){
        //終了時の処理は何もしない
        system.debug('■■■finish■■■');
    }
}
