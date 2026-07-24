//+------------------------------------------------------------------+
//| Risk Manager - Concrete Implementation                            |
//+------------------------------------------------------------------+
#ifndef RISKMANAGER_MQH_GUARD
#define RISKMANAGER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CRiskManager : public IRiskManager
{
private:
   SRiskMetrics            m_metrics;
   string                  m_config_json;
   bool                    m_initialized;
    
   double                  m_daily_realized_loss_limit;
   double                  m_floating_drawdown_threshold;
   double                  m_max_basket_loss;
   int                     m_max_total_open_trades;
   double                  m_max_symbol_exposure;
   bool                    m_session_restrictions_enabled;
   int                     m_session_start_hour;
   int                     m_session_end_hour;
   double                  m_spread_max;
   double                  m_slippage_max;
   int                     m_cooldown_minutes;
   double                  m_account_peak_equity;
   datetime                m_day_start;

   void                   ParseConfig(const string config_json);
   bool                   CheckSessionRestrictions();
   double                 GetCurrentSpread() const;

public:
   CRiskManager();
   virtual ~CRiskManager();
    
   virtual bool OnInit(const SRiskMetrics &initial_metrics, const string config_json);
   virtual void OnDeinit();
    
   virtual bool ValidateEntry(const SMoneyInput &money_input);
   virtual bool ValidateAddOn(const SMoneyInput &money_input);
   virtual bool ValidateExit(const SBasket &basket);
   virtual bool CheckEmergencyFlatten();
   virtual bool CheckDailyLossLimit();
   virtual bool CheckFloatingDrawdown();
   virtual bool CheckMaxBasketLoss(const SBasket &basket);
   virtual bool CheckMaxOpenTrades();
   virtual bool CheckMaxSymbolExposure(const string symbol);
   virtual bool CheckSessionRestrictions();
   virtual bool CheckSpreadFilter();
   virtual bool CheckSlippageFilter();
   virtual bool CheckCooldown();
   virtual bool TriggerCooldown(const datetime until);
   virtual SRiskMetrics GetMetrics();
   virtual string GetDiagnostics();
    
   virtual void UpdateMetrics();
   virtual void LoadParameters(const string config_json);
};

//+------------------------------------------------------------------+
//| CRiskManager Implementation                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager() : m_initialized(false),
   m_daily_realized_loss_limit(0.0),
   m_floating_drawdown_threshold(0.0),
   m_max_basket_loss(0.0),
   m_max_total_open_trades(0),
   m_max_symbol_exposure(0.0),
   m_session_restrictions_enabled(false),
   m_session_start_hour(0),
   m_session_end_hour(0),
   m_spread_max(0.0),
   m_slippage_max(0.0),
   m_cooldown_minutes(0),
   m_account_peak_equity(0.0),
   m_day_start(0)
{
   ZeroMemory(m_metrics);
}

CRiskManager::~CRiskManager()
{
   OnDeinit();
}

void CRiskManager::ParseConfig(const string config_json)
{
   m_daily_realized_loss_limit = 0.0;
   m_floating_drawdown_threshold = 0.0;
   m_max_basket_loss = 0.0;
   m_max_total_open_trades = 0;
   m_max_symbol_exposure = 0.0;
   m_session_restrictions_enabled = false;
   m_session_start_hour = 0;
   m_session_end_hour = 0;
   m_spread_max = 0.0;
   m_slippage_max = 0.0;
   m_cooldown_minutes = 0;
    
   if(config_json == "" || config_json == "0")
      return;
    
   string parts[];
   StringSplit(config_json, ';', parts);
    
   for(int i = 0; i < ArraySize(parts); i++)
   {
      if(parts[i] == "") continue;
        
      string kv[];
      StringSplit(parts[i], '=', kv);
        
      if(ArraySize(kv) < 2) continue;
        
      string key = StringTrim(kv[0]);
      string value = StringTrim(kv[1]);
        
      if(key == "daily_realized_loss_limit")
         m_daily_realized_loss_limit = StringToDouble(value);
      else if(key == "floating_drawdown_threshold")
         m_floating_drawdown_threshold = StringToDouble(value);
      else if(key == "max_basket_loss")
         m_max_basket_loss = StringToDouble(value);
      else if(key == "max_total_open_trades")
         m_max_total_open_trades = StringToInteger(value);
      else if(key == "max_symbol_exposure")
         m_max_symbol_exposure = StringToDouble(value);
      else if(key == "session_restrictions_enabled")
         m_session_restrictions_enabled = (value == "1" || value == "true");
      else if(key == "session_start_hour")
         m_session_start_hour = StringToInteger(value);
      else if(key == "session_end_hour")
         m_session_end_hour = StringToInteger(value);
      else if(key == "spread_max")
         m_spread_max = StringToDouble(value);
      else if(key == "slippage_max")
         m_slippage_max = StringToDouble(value);
      else if(key == "cooldown_minutes")
         m_cooldown_minutes = StringToInteger(value);
   }
}

bool CRiskManager::OnInit(const SRiskMetrics &initial_metrics, const string config_json)
{
   m_metrics = initial_metrics;
   m_config_json = config_json;
   m_initialized = true;
   m_day_start = TimeCurrent();
   m_account_peak_equity = 0.0;
    
   double equity = 0.0;
   if(AccountInfoDouble(ACCOUNT_EQUITY, equity))
      m_account_peak_equity = equity;
    
   ParseConfig(config_json);
   return true;
}

void CRiskManager::OnDeinit()
{
   m_initialized = false;
}

void CRiskManager::LoadParameters(const string config_json)
{
   m_config_json = config_json;
   ParseConfig(config_json);
}

bool CRiskManager::ValidateEntry(const SMoneyInput &money_input)
{
   if(!m_initialized) return false;
   if(!CheckEmergencyFlatten()) return false;
   if(!CheckDailyLossLimit()) return false;
   if(!CheckFloatingDrawdown()) return false;
   if(!CheckMaxOpenTrades()) return false;
   if(!CheckSessionRestrictions()) return false;
   if(!CheckSpreadFilter()) return false;
   if(!CheckCooldown()) return false;
   return true;
}

bool CRiskManager::ValidateAddOn(const SMoneyInput &money_input)
{
   return ValidateEntry(money_input);
}

bool CRiskManager::ValidateExit(const SBasket &basket)
{
   if(!m_initialized) return false;
   return true;
}

bool CRiskManager::CheckEmergencyFlatten()
{
   return !m_metrics.emergency_flatten_active;
}

bool CRiskManager::CheckDailyLossLimit()
{
   if(m_daily_realized_loss_limit <= 0.0) return true;
    
   datetime now = TimeCurrent();
   if(now >= m_day_start + 86400)
   {
      m_day_start = now;
      m_metrics.daily_realized_loss = 0.0;
   }
    
   return (m_metrics.daily_realized_loss > -m_daily_realized_loss_limit);
}

bool CRiskManager::CheckFloatingDrawdown()
{
   if(m_floating_drawdown_threshold <= 0.0) return true;
    
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0) return true;
    
   if(equity > m_account_peak_equity)
      m_account_peak_equity = equity;
    
   double drawdown = m_account_peak_equity - equity;
   return (drawdown < m_floating_drawdown_threshold);
}

bool CRiskManager::CheckMaxBasketLoss(const SBasket &basket)
{
   if(m_max_basket_loss <= 0.0) return true;
   if(basket.start_balance <= 0.0) return true;
    
   double floating_profit = 0.0;
   if(basket.state == BASKET_STATE_ACTIVE || basket.state == BASKET_STATE_TRAILING_ACTIVE || basket.state == BASKET_STATE_CLOSING)
   {
      floating_profit = basket.peak_floating_profit;
   }
    
   double basket_loss = -floating_profit;
   return (basket_loss < m_max_basket_loss);
}

bool CRiskManager::CheckMaxOpenTrades()
{
   if(m_max_total_open_trades <= 0) return true;
   return (m_metrics.total_open_trades < m_max_total_open_trades);
}

bool CRiskManager::CheckMaxSymbolExposure(const string symbol)
{
   if(m_max_symbol_exposure <= 0.0) return true;
   return (m_metrics.symbol_exposure < m_max_symbol_exposure);
}

bool CRiskManager::CheckSessionRestrictions()
{
   if(!m_session_restrictions_enabled) return true;
    
   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);
    
   int current_hour = dt.hour;
    
   if(m_session_start_hour <= m_session_end_hour)
   {
      return (current_hour >= m_session_start_hour && current_hour < m_session_end_hour);
   }
   else
   {
      return (current_hour >= m_session_start_hour || current_hour < m_session_end_hour);
   }
}

bool CRiskManager::CheckSpreadFilter()
{
   if(m_spread_max <= 0.0) return true;
    
   double spread = GetCurrentSpread();
   return (spread <= m_spread_max);
}

bool CRiskManager::CheckSlippageFilter()
{
   if(m_slippage_max <= 0.0) return true;
   return true;
}

bool CRiskManager::CheckCooldown()
{
   if(!m_metrics.cooldown_active) return true;
   return (TimeCurrent() >= m_metrics.cooldown_until);
}

bool CRiskManager::TriggerCooldown(const datetime until)
{
   m_metrics.cooldown_active = true;
   m_metrics.cooldown_until = until;
   return true;
}

double CRiskManager::GetCurrentSpread() const
{
   double ask = 0.0;
   double bid = 0.0;
    
   if(SymbolInfoDouble(_Symbol, SYMBOL_ASK, ask) && SymbolInfoDouble(_Symbol, SYMBOL_BID, bid))
      return (ask - bid);
    
   return 0.0;
}

SRiskMetrics CRiskManager::GetMetrics()
{
   return m_metrics;
}

void CRiskManager::UpdateMetrics()
{
   if(!m_initialized) return;
    
   double equity = 0.0;
   if(AccountInfoDouble(ACCOUNT_EQUITY, equity))
   {
      if(equity > m_account_peak_equity)
         m_account_peak_equity = equity;
   }
    
   m_metrics.total_open_trades = 0;
   m_metrics.symbol_exposure = 0.0;
    
   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
        
      if(PositionGetInteger(POSITION_MAGIC) == (long)AccountInfoInteger(ACCOUNT_MAGIC))
      {
         m_metrics.total_open_trades++;
            
         double volume = PositionGetDouble(POSITION_VOLUME);
         m_metrics.symbol_exposure += volume;
      }
   }
}

string CRiskManager::GetDiagnostics()
{
   return StringConcatenate("risk: daily_loss=", DoubleToString(m_metrics.daily_realized_loss), " open_trades=", IntegerToString(m_metrics.total_open_trades), " cooldown=", (m_metrics.cooldown_active ? "yes" : "no"), " emergency=", (m_metrics.emergency_flatten_active ? "yes" : "no"));
}

#endif // RISKMANAGER_MQH_GUARD
