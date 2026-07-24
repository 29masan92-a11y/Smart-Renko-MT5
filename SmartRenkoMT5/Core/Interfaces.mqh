//+------------------------------------------------------------------+
//| Renko Data Provider Interface                                     |
//+------------------------------------------------------------------+
#ifndef INTERFACES_MQH_GUARD
#define INTERFACES_MQH_GUARD

class IRenkoDataProvider
{
public:
   virtual bool      OnInit(const string symbol, const double brick_size) = 0;
   virtual void      OnDeinit() = 0;
   virtual bool      OnTick() = 0;
   
   virtual bool      GetCurrentBrick(SRenkoBrick &brick) = 0;
   virtual ENUM_SIGNAL_DIRECTION GetDirection() = 0;
   virtual bool      IsContinuation() = 0;
   virtual bool      IsReversal() = 0;
   virtual double    GetBrickSize() = 0;
   virtual bool      GetHistoricalContext(const int count, SRenkoBrick &bricks[]) = 0;
   virtual bool      IsFresh(const datetime max_age_seconds = 60) = 0;
   virtual int       GetBrickIndex() = 0;
   virtual void      SetBrickSize(const double size) = 0;
   virtual string    GetStatus() = 0;
};

//+------------------------------------------------------------------+
//| Entry Strategy Interface                                          |
//+------------------------------------------------------------------+
class IEntryStrategy
{
public:
   virtual bool      OnInit(const string symbol, const long magic_number) = 0;
   virtual void      OnDeinit() = 0;
   virtual void      LoadParameters(const string params) = 0;
   
   virtual bool      IsEligible(const SRenkoBrick &brick, const ENUM_TRADING_MODE mode) = 0;
   virtual bool      GenerateSignal(SSignal &signal, const SRenkoBrick &brick) = 0;
   virtual string    GetDiagnostics() = 0;
   virtual string    GetName() = 0;
};

//+------------------------------------------------------------------+
//| Exit Strategy Interface                                           |
//+------------------------------------------------------------------+
class IExitStrategy
{
public:
   virtual bool      OnInit(const string symbol, const long magic_number) = 0;
   virtual void      OnDeinit() = 0;
   virtual void      LoadParameters(const string params) = 0;
   
   virtual bool      EvaluateClose(const SBasket &basket, const SPosition &position, const double current_profit) = 0;
   virtual bool      EvaluateReduce(const SBasket &basket, const SPosition &position, const double current_profit) = 0;
   virtual string    GetDiagnostics() = 0;
   virtual string    GetName() = 0;
};

//+------------------------------------------------------------------+
//| Execution Adapter Interface                                       |
//+------------------------------------------------------------------+
class IExecutionAdapter
{
public:
   virtual bool      OnInit(const string symbol, const long magic_number) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual SExecutionResult SendOrder(const ENUM_BROKER_ORDER_TYPE type, const double volume, const double price, const double sl, const double tp, const string comment) = 0;
   virtual bool      ClosePosition(const ulong ticket) = 0;
   virtual bool      CloseAllPositions() = 0;
   virtual bool      ModifyPosition(const ulong ticket, const double sl, const double tp) = 0;
   virtual bool      GetOpenPositions(SPosition &positions[], const string symbol = "", const long magic = -1) = 0;
   virtual bool      GetAccountInfo(double &balance, double &equity, double &free_margin, double &margin) = 0;
   virtual bool      GetSymbolInfo(const string symbol, double &lot_step, double &min_lot, double &max_lot, double &point, int &digits) = 0;
   virtual bool      IsConnected() = 0;
   virtual string    GetLastError() = 0;
};

//+------------------------------------------------------------------+
//| Persistence Layer Interface                                       |
//+------------------------------------------------------------------+
class IPersistenceLayer
{
public:
   virtual bool      OnInit(const string prefix) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      SaveBasket(const SBasket &basket) = 0;
   virtual bool      LoadBasket(string id, SBasket &basket) = 0;
   virtual bool      DeleteBasket(const string id) = 0;
   virtual bool      SavePositions(const SPosition &positions[], const int count) = 0;
   virtual bool      LoadPositions(SPosition &positions[], int &count) = 0;
   virtual bool      SaveTrailingState(const string basket_id, const double peak_profit, const bool activated) = 0;
   virtual bool      LoadTrailingState(const string basket_id, double &peak_profit, bool &activated) = 0;
   virtual bool      SaveBalanceSnapshot(const string basket_id, const double balance) = 0;
   virtual bool      LoadBalanceSnapshot(const string basket_id, double &balance) = 0;
   virtual bool      SaveModeState(const ENUM_TRADING_MODE mode) = 0;
   virtual bool      LoadModeState(ENUM_TRADING_MODE &mode) = 0;
   virtual bool      SavePendingProtection(const SRiskMetrics &metrics) = 0;
   virtual bool      LoadPendingProtection(SRiskMetrics &metrics) = 0;
   virtual bool      ClearAll() = 0;
   virtual bool      ListBaskets(string &basket_ids[], int &count) = 0;
   virtual string    GetStatus() = 0;
};

//+------------------------------------------------------------------+
//| Notification Manager Interface                                    |
//+------------------------------------------------------------------+
class INotificationManager
{
public:
   virtual bool      OnInit(const bool enable_push, const bool enable_email, const bool enable_sound) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      Send(const string subject, const string message) = 0;
   virtual bool      SendBasketEvent(const string basket_id, const ENUM_BASKET_STATE state, const string details) = 0;
   virtual bool      SendRiskAlert(const string alert_type, const string message) = 0;
   virtual bool      SendTradeEvent(const string symbol, const ENUM_BROKER_ORDER_TYPE type, const double volume, const double price) = 0;
   virtual bool      IsEnabled() = 0;
};

//+------------------------------------------------------------------+
//| Reporting Engine Interface                                        |
//+------------------------------------------------------------------+
class IReportingEngine
{
public:
   virtual bool      OnInit(const string report_path) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      GenerateHtml(const SBasketMetrics &metrics, const string file_path) = 0;
   virtual bool      GenerateCsv(const SBasketMetrics &metrics[], const int count, const string file_path) = 0;
   virtual bool      GenerateJson(const SBasketMetrics &metrics[], const int count, const string file_path) = 0;
   virtual bool      ExportSessionReport(const datetime start, const datetime end) = 0;
};

//+------------------------------------------------------------------+
//| GUI Layer Interface                                               |
//+------------------------------------------------------------------+
class IGuiLayer
{
public:
   virtual bool      OnInit(const long chart_id, const int subwin) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual void      UpdateState(const ENUM_BASKET_STATE state, const string basket_id) = 0;
   virtual void      UpdateSignalStrength(const double strength, const ENUM_SIGNAL_DIRECTION direction) = 0;
   virtual void      UpdateBasketMetrics(const SBasketMetrics &metrics) = 0;
   virtual void      UpdateRiskStatus(const SRiskMetrics &metrics) = 0;
   virtual bool      ProcessUserCommand(const string command, string &response) = 0;
   virtual bool      IsVisible() = 0;
   virtual void      Show() = 0;
   virtual void      Hide() = 0;
   virtual void      Refresh() = 0;
};

//+------------------------------------------------------------------+
//| Preset / Profile Manager Interface                               |
//+------------------------------------------------------------------+
class IPresetProfileManager
{
public:
   virtual bool      OnInit(const string profiles_path) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      SaveProfile(const SPresetProfile &profile, const string json_data) = 0;
   virtual bool      LoadProfile(const string name, SPresetProfile &profile, string &json_data) = 0;
   virtual bool      DeleteProfile(const string name) = 0;
   virtual bool      ListProfiles(string &names[]) = 0;
   virtual bool      ImportProfile(const string file_path, string &imported_name) = 0;
   virtual bool      ExportProfile(const string name, const string file_path) = 0;
   virtual string    GetActiveProfile() = 0;
   virtual bool      SetActiveProfile(const string name) = 0;
};

//+------------------------------------------------------------------+
//| VPS Runner Layer Interface                                        |
//+------------------------------------------------------------------+
class IVpsRunner
{
public:
   virtual bool      OnInit(const string symbol, const long magic_number) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      Start() = 0;
   virtual bool      Stop() = 0;
   virtual bool      EmergencyClose() = 0;
   virtual bool      IsRunning() = 0;
   virtual string    GetStatus() = 0;
   virtual double    GetCpuUsageEstimate() = 0;
   virtual double    GetMemoryUsageEstimate() = 0;
};

#endif // INTERFACES_MQH_GUARD
