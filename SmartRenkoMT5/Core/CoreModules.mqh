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
    int                     m_last_processed_brick_index;
    bool                    m_manual_entry_requested;
    ENUM_POSITION_TYPE      m_manual_entry_direction;

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
    bool   RequestManualEntry(const ENUM_POSITION_TYPE direction);
    
private:
    void   ProcessIdleState(const SRenkoBrick &brick);
    void   ProcessPendingFirstEntry(const SBasket &basket);
    void   ProcessActiveOrTrailingBasket(const SBasket &basket, const SRenkoBrick &brick);
    void   ProcessClosingBasket(const SBasket &basket);
    void   ProcessRecoveryBasket(const SBasket &basket);
    bool   TryOpenNewBasket(const ENUM_POSITION_TYPE direction);
    bool   TryOpenFirstEntry(const string basket_id);
    bool   TryAddOnEntry(const SBasket &basket, const SRenkoBrick &brick);
    bool   TryCloseActiveBasket(const SBasket &basket);
    SMoneyInput BuildMoneyInput(const string basket_id, const bool is_add_on, const int add_entry_number) const;
    double  GetAccountBalance() const;
    double  GetAccountEquity() const;
    double  GetFreeMargin() const;
};

//+------------------------------------------------------------------+
//| CCoreOrchestrator Implementation                                 |
//+------------------------------------------------------------------+
CCoreOrchestrator::CCoreOrchestrator() : m_symbol(""),
   m_magic_number(0),
   m_trading_mode(TRADING_MODE_FULL_AUTO),
   m_initialized(false),
   m_last_tick_time(0),
   m_last_processed_brick_index(-1),
   m_manual_entry_requested(false),
   m_manual_entry_direction(POSITION_TYPE_LONG)
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
   m_last_processed_brick_index = -1;
   m_manual_entry_requested = false;
   m_manual_entry_direction = POSITION_TYPE_LONG;
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
    
   SRenkoBrick current_brick;
   ZeroMemory(current_brick);
   if(m_renko_provider != NULL)
      m_renko_provider.GetCurrentBrick(current_brick);
   if(current_brick.brick_size <= 0.0)
      return;
    
   if(current_brick.brick_index == m_last_processed_brick_index)
      return;
   m_last_processed_brick_index = current_brick.brick_index;
    
   if(m_position_manager != NULL)
      m_position_manager.UpdatePositionProfit();
    
   SBasket active_basket;
   ZeroMemory(active_basket);
   bool has_active_basket = false;
   if(m_basket_manager != NULL)
      has_active_basket = m_basket_manager.GetActiveBasket(active_basket);
    
   if(!has_active_basket)
   {
      ProcessIdleState(current_brick);
   }
   else
   {
      switch(active_basket.state)
      {
         case BASKET_STATE_PENDING_FIRST_ENTRY:
            ProcessPendingFirstEntry(active_basket);
            break;
         case BASKET_STATE_ACTIVE:
         case BASKET_STATE_TRAILING_ACTIVE:
            ProcessActiveOrTrailingBasket(active_basket, current_brick);
            break;
         case BASKET_STATE_CLOSING:
            ProcessClosingBasket(active_basket);
            break;
         case BASKET_STATE_RECOVERY_REBUILD:
            ProcessRecoveryBasket(active_basket);
            break;
         default:
            break;
      }
   }
    
   if(m_gui_layer != NULL)
      m_gui_layer.Refresh();
}

bool CCoreOrchestrator::RequestManualEntry(const ENUM_POSITION_TYPE direction)
{
   if(!m_initialized) return false;
   if(direction != POSITION_TYPE_LONG && direction != POSITION_TYPE_SHORT)
      return false;
    
   m_manual_entry_requested = true;
   m_manual_entry_direction = direction;
   return true;
}

void CCoreOrchestrator::ProcessIdleState(const SRenkoBrick &brick)
{
   if(m_manual_entry_requested)
   {
      ENUM_POSITION_TYPE dir = m_manual_entry_direction;
      m_manual_entry_requested = false;
      if(dir == POSITION_TYPE_LONG || dir == POSITION_TYPE_SHORT)
      {
         TryOpenNewBasket(dir);
      }
      return;
   }
    
   if(m_trading_mode == TRADING_MODE_MANUAL)
      return;
    
   SSignal signal;
   ZeroMemory(signal);
   if(m_signal_manager == NULL) return;
   if(!m_signal_manager->AggregateSignals(signal))
      return;
   if(signal.direction == SIGNAL_DIRECTION_NONE)
      return;
    
   ENUM_POSITION_TYPE dir = (signal.direction == SIGNAL_DIRECTION_BUY) ? POSITION_TYPE_LONG : POSITION_TYPE_SHORT;
   TryOpenNewBasket(dir);
}

void CCoreOrchestrator::ProcessPendingFirstEntry(const SBasket &basket)
{
   TryOpenFirstEntry(basket.id);
}

void CCoreOrchestrator::ProcessActiveOrTrailingBasket(const SBasket &basket, const SRenkoBrick &brick)
{
   if(m_trailing_manager != NULL && m_trailing_manager->IsActive())
   {
      double total_profit = 0.0;
      if(m_position_manager != NULL)
         total_profit = m_position_manager->GetTotalProfit(basket.id);
        
      if(m_trailing_manager->Evaluate(total_profit))
      {
         TryCloseActiveBasket(basket);
         return;
      }
   }
    
   SPosition positions[];
   int pos_count = 0;
   if(m_position_manager != NULL)
      m_position_manager->GetPositionsByBasket(basket.id, positions, pos_count);
    
   for(int i = 0; i < pos_count; i++)
   {
      if(!positions[i].is_active) continue;
        
      SSignal exit_signal;
      ZeroMemory(exit_signal);
      if(m_signal_manager->AggregateExitSignals(exit_signal, basket, positions[i], positions[i].profit))
      {
         TryCloseActiveBasket(basket);
         return;
      }
   }
    
   if(basket.state == BASKET_STATE_ACTIVE && m_renko_provider != NULL && m_renko_provider.IsContinuation())
   {
      TryAddOnEntry(basket, brick);
   }
}

void CCoreOrchestrator::ProcessClosingBasket(const SBasket &basket)
{
   if(m_position_manager == NULL) return;
    
   int open_count = m_position_manager->GetOpenPositionCountByBasket(basket.id);
   if(open_count <= 0)
   {
      if(m_basket_manager != NULL)
         m_basket_manager->UpdateBasketState(basket.id, BASKET_STATE_CLOSED);
   }
}

void CCoreOrchestrator::ProcessRecoveryBasket(const SBasket &basket)
{
   if(m_position_manager == NULL) return;
    
   SPosition positions[];
   int count = 0;
   m_position_manager->GetPositionsByBasket(basket.id, positions, count);
    
   int active_count = 0;
   for(int i = 0; i < count; i++)
   {
      if(positions[i].is_active)
         active_count++;
   }
    
   if(active_count > 0)
   {
      if(m_basket_manager != NULL)
      {
         m_basket_manager->UpdateBasketState(basket.id, BASKET_STATE_ACTIVE);
            
         if(m_trailing_manager != NULL && basket.trailing_activated)
         {
            m_trailing_manager->RestoreState(basket.peak_floating_profit, true);
         }
      }
   }
   else
   {
      if(m_basket_manager != NULL)
      {
         m_basket_manager->CloseBasket(basket.id, CLOSURE_REASON_RECOVERY);
         m_basket_manager->UpdateBasketState(basket.id, BASKET_STATE_CLOSED);
      }
   }
}

bool CCoreOrchestrator::TryOpenNewBasket(const ENUM_POSITION_TYPE direction)
{
   if(m_basket_manager == NULL) return false;
   if(m_risk_manager == NULL) return false;
   if(m_money_manager == NULL) return false;
   if(m_position_manager == NULL) return false;
   if(m_execution_adapter == NULL) return false;
    
   if(!m_basket_manager->CreateBasket(direction))
      return false;
    
   SBasket basket;
   if(!m_basket_manager->GetActiveBasket(basket))
      return false;
    
   if(!TryOpenFirstEntry(basket.id))
   {
      m_basket_manager->CloseBasket(basket.id, CLOSURE_REASON_NONE);
      m_basket_manager->UpdateBasketState(basket.id, BASKET_STATE_IDLE);
      return false;
   }
    
   return true;
}

bool CCoreOrchestrator::TryOpenFirstEntry(const string basket_id)
{
   if(m_execution_adapter == NULL) return false;
   if(m_risk_manager == NULL) return false;
   if(m_money_manager == NULL) return false;
   if(m_position_manager == NULL) return false;
   if(m_basket_manager == NULL) return false;
    
   SBasket basket;
   if(!m_basket_manager->GetActiveBasket(basket))
      return false;
    
   SMoneyInput money_input = BuildMoneyInput(basket_id, false, 0);
   if(!m_risk_manager->ValidateEntry(money_input))
      return false;
    
   SMoneyResult lot_result = m_money_manager->CalculateLot(money_input);
   if(!lot_result.allowed)
      return false;
    
   double lot_step, min_lot, max_lot, point;
   int digits;
   if(!m_execution_adapter->GetSymbolInfo(m_symbol, lot_step, min_lot, max_lot, point, digits))
      return false;
    
   if(!m_money_manager->ValidateLot(lot_result.suggested_lot, min_lot, max_lot, lot_step))
      return false;
    
   double price = 0.0;
   if(m_renko_provider != NULL)
   {
      SRenkoBrick brick;
      if(m_renko_provider->GetCurrentBrick(brick))
         price = brick.price;
   }
   if(price <= 0.0)
   {
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      if(bid > 0.0 && ask > 0.0)
         price = (bid + ask) / 2.0;
   }
   if(price <= 0.0)
      return false;
    
   string comment = StringConcatenate("SR_First_", basket.id);
   if(!m_position_manager->OpenPosition(basket_id, basket.direction, lot_result.suggested_lot, price, 0.0, 0.0, comment))
      return false;
    
   m_basket_manager->UpdateBasketState(basket_id, BASKET_STATE_ACTIVE);
    
   double balance = GetAccountBalance();
   m_basket_manager->SetStartBalance(basket_id, balance);
    
   if(m_trailing_manager != NULL)
   {
      m_trailing_manager->OnInit(basket_id, balance, 0.0, 0.0, "{}");
   }
    
   if(m_persistence_layer != NULL)
   {
      SBasket updated_basket;
      if(m_basket_manager->GetActiveBasket(updated_basket))
         m_persistence_layer->SaveBasket(updated_basket);
   }
    
   return true;
}

bool CCoreOrchestrator::TryAddOnEntry(const SBasket &basket, const SRenkoBrick &brick)
{
   if(m_risk_manager == NULL) return false;
   if(m_money_manager == NULL) return false;
   if(m_execution_adapter == NULL) return false;
   if(m_position_manager == NULL) return false;
   if(m_basket_manager == NULL) return false;
   if(m_signal_manager == NULL) return false;
    
   if(m_renko_provider == NULL || !m_renko_provider.IsContinuation())
      return false;
    
   SSignal signal;
   ZeroMemory(signal);
   if(!m_signal_manager->AggregateSignals(signal))
      return false;
    
   ENUM_POSITION_TYPE signal_dir = (signal.direction == SIGNAL_DIRECTION_BUY) ? POSITION_TYPE_LONG : POSITION_TYPE_SHORT;
   if(signal_dir != basket.direction)
      return false;
    
   SMoneyInput money_input = BuildMoneyInput(basket.id, true, basket.add_entry_count + 1);
   if(!m_risk_manager->ValidateAddOn(money_input))
      return false;
    
   SMoneyResult lot_result = m_money_manager->CalculateLot(money_input);
   if(!lot_result.allowed)
      return false;
    
   double lot_step, min_lot, max_lot, point;
   int digits;
   if(!m_execution_adapter->GetSymbolInfo(m_symbol, lot_step, min_lot, max_lot, point, digits))
      return false;
    
   if(!m_money_manager->ValidateLot(lot_result.suggested_lot, min_lot, max_lot, lot_step))
      return false;
    
   string comment = StringConcatenate("SR_AddOn_", IntegerToString(basket.add_entry_count + 1));
   if(!m_position_manager->OpenPosition(basket.id, basket.direction, lot_result.suggested_lot, brick.price, 0.0, 0.0, comment))
      return false;
    
   m_basket_manager->AddEntry(basket.id);
    
   if(m_persistence_layer != NULL)
   {
      SBasket updated_basket;
      if(m_basket_manager->GetActiveBasket(updated_basket))
         m_persistence_layer->SaveBasket(updated_basket);
   }
    
   return true;
}

bool CCoreOrchestrator::TryCloseActiveBasket(const SBasket &basket)
{
   if(m_basket_manager == NULL) return false;
   if(m_position_manager == NULL) return false;
    
   ENUM_CLOSURE_REASON reason = CLOSURE_REASON_NONE;
   if(m_trailing_manager != NULL && m_trailing_manager->IsActive())
      reason = CLOSURE_REASON_TRAILING_STOP;
    
   if(!m_basket_manager->CloseBasket(basket.id, reason))
      return false;
    
   m_position_manager->CloseAllPositions(basket.id);
    
   if(m_notification_manager != NULL)
      m_notification_manager->SendBasketEvent(basket.id, BASKET_STATE_CLOSING, "basket closing");
    
   return true;
}

SMoneyInput CCoreOrchestrator::BuildMoneyInput(const string basket_id, const bool is_add_on, const int add_entry_number) const
{
   SMoneyInput input;
   ZeroMemory(input);
   input.balance = GetAccountBalance();
   input.equity = GetAccountEquity();
   input.free_margin = GetFreeMargin();
   input.trading_mode = m_trading_mode;
   input.is_add_on = is_add_on;
   input.add_entry_number = add_entry_number;
   input.basket_risk_percent = 1.0;
   input.stop_loss_pips = 0.0;
   return input;
}

double CCoreOrchestrator::GetAccountBalance() const
{
   if(m_execution_adapter == NULL)
      return 0.0;
    
   double balance = 0.0, equity = 0.0, margin = 0.0, free_margin = 0.0;
   if(m_execution_adapter->GetAccountInfo(balance, equity, free_margin, margin))
      return balance;
    
   return 0.0;
}

double CCoreOrchestrator::GetAccountEquity() const
{
   if(m_execution_adapter == NULL)
      return 0.0;
    
   double balance = 0.0, equity = 0.0, margin = 0.0, free_margin = 0.0;
   if(m_execution_adapter->GetAccountInfo(balance, equity, free_margin, margin))
      return equity;
    
   return 0.0;
}

double CCoreOrchestrator::GetFreeMargin() const
{
   if(m_execution_adapter == NULL)
      return 0.0;
    
   double balance = 0.0, equity = 0.0, margin = 0.0, free_margin = 0.0;
   if(m_execution_adapter->GetAccountInfo(balance, equity, free_margin, margin))
      return free_margin;
    
   return 0.0;
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
