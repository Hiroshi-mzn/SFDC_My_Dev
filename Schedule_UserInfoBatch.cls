////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    2019.06.17 cookpad課題「User API連携」
//
//    Title:Schedule_UserInfoBatch
//    ------------------------
//    Author:Hiroshi Mizuno
//    Create:2019.06.15
//
//    [Description]
//    ・対象のUser.idの範囲を指定する場合はコンソールからスケジュール登録
//    ・指定しない場合のデフォルト値はカスタム表示ラベルの設定値とする
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

global class Schedule_UserInfoBatch implements Schedulable {
    
    private final Integer BATCH_SIZE = 200;
    private Integer StartNum;
    private Integer EndNum;
    
    global void execute(SchedulableContext ctx) {
    
        Database.executeBatch(new Batch_GetUserInfo(StartNum,EndNum), BATCH_SIZE);
    
    }
}
