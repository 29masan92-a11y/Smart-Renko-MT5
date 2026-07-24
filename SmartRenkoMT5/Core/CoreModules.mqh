//+------------------------------------------------------------------+
//| Core Orchestrator                                                 |
//+------------------------------------------------------------------+
#ifndef COREMODULES_MQH_GUARD
#define COREMODULES_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CCoreOrchestrator
{
private:
   IRenkoDataProvider*     m_renko_provider;
   IEntryStrategy*         m_entry_strategy;
   IExitStrategy*          m_exit_strategy;
   ISignalManager*         m_signal_manager;
   IBasketManager*         m_basket_manager;
   IPositionManager*       m_position_manager;
   IRiskManager*           m_risk_manager;
   IMoneyManager*          m_money_manager;
   ITrailingManager*       m_trailing_manager;
   IExecutionAdapter*      m_execution_adapter;
   IPersistenceLayer*      m_persistence_layer;
   INotificationManager*   m_notification_manager;
   IReportingEngine*       m_reporting_engine;
   IGuiLayer*              m_gui_layer;
   IPresetProfileManager*  m_preset_manager;
   IVpsRunner*             m_vps_runner;
   
   string                  m_symbol;
   long                    m_magic_number;
   ENUM_TRADING_MODE       m_trading_mode;
   bool                    m_initialized;
   datetime                m_last_tick_time;

public:
   CCoreOrchestrator();
   ~CCoreOrchestrator();
   
   bool   Init(const string symbol, const long magic, const ENUM_TRADING_MODE mode);
   void   Deinit();
   void   OnTick();
   void   OnTimer();
   void   OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
   
   bool   IsInitialized() const { return m_initialized; }
   string GetStatus() const;
   
   bool   SetRenkoProvider(IRenkoDataProvider* provider);
   bool   SetEntryStrategy(IEntryStrategy* strategy);
   bool   SetExitStrategy(IExitStrategy* strategy);
   bool   SetSignalManager(ISignalManager* manager);
   bool   SetBasketManager(IBasketManager* manager);
   bool   SetPositionManager(IPositionManager* manager);
   bool   SetRiskManager(IRiskManager* manager);
   bool   SetMoneyManager(IMoneyManager* manager);
   bool   SetTrailingManager(ITrailingManager* manager);
   bool   SetExecutionAdapter(IExecutionAdapter* adapter);
   bool   SetPersistenceLayer(IPersistenceLayer* persistence);
   bool   SetNotificationManager(INotificationManager* notifier);
   bool   SetReportingEngine(IReportingEngine* reporter);
   bool   SetGuiLayer(IGuiLayer* gui);
   bool   SetPresetManager(IPresetProfileManager* preset);
   bool   SetVpsRunner(IVpsRunner* vps);
   
   bool   EmergencyFlatten();
   bool   ForceCloseBasket(const string basket_id);
};

//+------------------------------------------------------------------+
//| Signal Manager                                                    |
//+------------------------------------------------------------------+
class ISignalManager
{
public:
   virtual bool      OnInit(const long magic_number) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      RegisterEntryStrategy(IEntryStrategy* strategy) = 0;
   virtual bool      RegisterExitStrategy(IExitStrategy* strategy) = 0;
   virtual bool      AggregateSignals(SSignal &final_signal) = 0;
   virtual bool      NormalizeSignal(SSignal &signal) = 0;
   virtual string    GetDiagnostics() = 0;
};

//+------------------------------------------------------------------+
//| Basket Manager                                                    |
//+------------------------------------------------------------------+
class IBasketManager
{
public:
   virtual bool      OnInit(const string symbol, const long magic_number, IPersistenceLayer* persistence) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      CreateBasket(const ENUM_POSITION_TYPE direction) = 0;
   virtual bool      GetActiveBasket(SBasket &basket) = 0;
   virtual bool      UpdateBasketState(const string basket_id, const ENUM_BASKET_STATE new_state) = 0;
   virtual bool      CloseBasket(const string basket_id, const ENUM_CLOSURE_REASON reason) = 0;
   virtual bool      AddEntry(const string basket_id) = 0;
   virtual bool      ReconstructFromPositions() = 0;
   virtual bool      ReconstructFromPersistence() = 0;
   virtual string    GetDiagnostics() = 0;
   virtual int       GetActiveBasketCount() = 0;
};

//+------------------------------------------------------------------+
//| Position Manager                                                  |
//+------------------------------------------------------------------+
class IPositionManager
{
public:
   virtual bool      OnInit(const string symbol, const long magic_number, IExecutionAdapter* adapter) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      OpenPosition(const string basket_id, const ENUM_POSITION_TYPE type, const double volume, const double price, const double sl, const double tp, const string comment) = 0;
   virtual bool      ClosePosition(const ulong ticket) = 0;
   virtual bool      CloseAllPositions(const string basket_id) = 0;
   virtual bool      GetPositionsByBasket(const string basket_id, SPosition &positions[], int &count) = 0;
   virtual bool      GetOpenPositions(SPosition &positions[], int &count) = 0;
   virtual bool      UpdatePositionProfit() = 0;
   virtual double    GetTotalProfit(const string basket_id = "") = 0;
   virtual int       GetOpenPositionCount() = 0;
   virtual string    GetDiagnostics() = 0;
};

//+------------------------------------------------------------------+
//| Risk Manager                                                      |
//+------------------------------------------------------------------+
class IRiskManager
{
public:
   virtual bool      OnInit(const SRiskMetrics &initial_metrics, const string config_json) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      ValidateEntry(const SMoneyInput &money_input) = 0;
   virtual bool      ValidateAddOn(const SMoneyInput &money_input) = 0;
   virtual bool      ValidateExit(const SBasket &basket) = 0;
   virtual bool      CheckEmergencyFlatten() = 0;
   virtual bool      CheckDailyLossLimit() = 0;
   virtual bool      CheckMaxOpenTrades() = 0;
   virtual bool      CheckSpreadFilter() = 0;
   virtual bool      CheckCooldown() = 0;
   virtual bool      TriggerCooldown(const datetime until) = 0;
   virtual SRiskMetrics GetMetrics() = 0;
   virtual string    GetDiagnostics() = 0;
};

//+------------------------------------------------------------------+
//| Money Manager                                                     |
//+------------------------------------------------------------------+
class IMoneyManager
{
public:
   virtual bool      OnInit(const string config_json) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual SMoneyResult CalculateLot(const SMoneyInput &input) = 0;
   virtual bool      ValidateLot(const double lot, const double min_lot, const double max_lot, const double lot_step) = 0;
   virtual string    GetDiagnostics() = 0;
};

//+------------------------------------------------------------------+
//| Trailing Manager                                                  |
//+------------------------------------------------------------------+
class ITrailingManager
{
public:
   virtual bool      OnInit(const string basket_id, const double start_balance, const double threshold, const double trail_amount, const string config_json) = 0;
   virtual void      OnDeinit() = 0;
   
   virtual bool      Evaluate(const double current_floating_profit) = 0;
   virtual bool      IsActive() = 0;
   virtual double    GetPeakProfit() = 0;
   virtual bool      RestoreState(const double peak_profit, const bool activated) = 0;
   virtual string    GetDiagnostics() = 0;
};

#endif // COREMODULES_MQH_GUARD
