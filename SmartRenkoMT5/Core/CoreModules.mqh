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
//| CCoreOrchestrator Implementation                                 |
//+------------------------------------------------------------------+
CCoreOrchestrator::CCoreOrchestrator() : m_symbol(""),
   m_magic_number(0),
   m_trading_mode(TRADING_MODE_FULL_AUTO),
   m_initialized(false),
   m_last_tick_time(0)
{
   m_renko_provider = NULL;
   m_entry_strategy = NULL;
   m_exit_strategy = NULL;
   m_signal_manager = NULL;
   m_basket_manager = NULL;
   m_position_manager = NULL;
   m_risk_manager = NULL;
   m_money_manager = NULL;
   m_trailing_manager = NULL;
   m_execution_adapter = NULL;
   m_persistence_layer = NULL;
   m_notification_manager = NULL;
   m_reporting_engine = NULL;
   m_gui_layer = NULL;
   m_preset_manager = NULL;
   m_vps_runner = NULL;
}

CCoreOrchestrator::~CCoreOrchestrator()
{
   Deinit();
}

bool CCoreOrchestrator::Init(const string symbol, const long magic, const ENUM_TRADING_MODE mode)
{
   m_symbol = symbol;
   m_magic_number = magic;
   m_trading_mode = mode;
   m_initialized = true;
   m_last_tick_time = TimeCurrent();
   return true;
}

void CCoreOrchestrator::Deinit()
{
   m_initialized = false;
}

void CCoreOrchestrator::OnTick()
{
   if(!m_initialized) return;
   m_last_tick_time = TimeCurrent();
}

void CCoreOrchestrator::OnTimer()
{
}

void CCoreOrchestrator::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
}

string CCoreOrchestrator::GetStatus() const
{
   return StringConcatenate("symbol=", m_symbol, " magic=", IntegerToString(m_magic_number), " mode=", EnumToString(m_trading_mode), " initialized=", (m_initialized ? "yes" : "no"));
}

bool CCoreOrchestrator::SetRenkoProvider(IRenkoDataProvider* provider)
{
   m_renko_provider = provider;
   return true;
}

bool CCoreOrchestrator::SetEntryStrategy(IEntryStrategy* strategy)
{
   m_entry_strategy = strategy;
   return true;
}

bool CCoreOrchestrator::SetExitStrategy(IExitStrategy* strategy)
{
   m_exit_strategy = strategy;
   return true;
}

bool CCoreOrchestrator::SetSignalManager(ISignalManager* manager)
{
   m_signal_manager = manager;
   return true;
}

bool CCoreOrchestrator::SetBasketManager(IBasketManager* manager)
{
   m_basket_manager = manager;
   return true;
}

bool CCoreOrchestrator::SetPositionManager(IPositionManager* manager)
{
   m_position_manager = manager;
   return true;
}

bool CCoreOrchestrator::SetRiskManager(IRiskManager* manager)
{
   m_risk_manager = manager;
   return true;
}

bool CCoreOrchestrator::SetMoneyManager(IMoneyManager* manager)
{
   m_money_manager = manager;
   return true;
}

bool CCoreOrchestrator::SetTrailingManager(ITrailingManager* manager)
{
   m_trailing_manager = manager;
   return true;
}

bool CCoreOrchestrator::SetExecutionAdapter(IExecutionAdapter* adapter)
{
   m_execution_adapter = adapter;
   return true;
}

bool CCoreOrchestrator::SetPersistenceLayer(IPersistenceLayer* persistence)
{
   m_persistence_layer = persistence;
   return true;
}

bool CCoreOrchestrator::SetNotificationManager(INotificationManager* notifier)
{
   m_notification_manager = notifier;
   return true;
}

bool CCoreOrchestrator::SetReportingEngine(IReportingEngine* reporter)
{
   m_reporting_engine = reporter;
   return true;
}

bool CCoreOrchestrator::SetGuiLayer(IGuiLayer* gui)
{
   m_gui_layer = gui;
   return true;
}

bool CCoreOrchestrator::SetPresetManager(IPresetProfileManager* preset)
{
   m_preset_manager = preset;
   return true;
}

bool CCoreOrchestrator::SetVpsRunner(IVpsRunner* vps)
{
   m_vps_runner = vps;
   return true;
}

bool CCoreOrchestrator::EmergencyFlatten()
{
   if(m_execution_adapter != NULL)
      m_execution_adapter.CloseAllPositions();
   return true;
}

bool CCoreOrchestrator::ForceCloseBasket(const string basket_id)
{
   if(m_basket_manager != NULL)
      m_basket_manager.CloseBasket(basket_id, CLOSURE_REASON_EMERGENCY_FLATTEN);
   if(m_position_manager != NULL)
      m_position_manager.CloseAllPositions(basket_id);
   return true;
}

#endif // COREMODULES_MQH_GUARD
