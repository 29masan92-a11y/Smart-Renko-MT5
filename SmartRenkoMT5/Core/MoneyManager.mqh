//+------------------------------------------------------------------+
//| Money Manager - Concrete Implementation                           |
//+------------------------------------------------------------------+
#ifndef MONEYMANAGER_MQH_GUARD
#define MONEYMANAGER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CMoneyManager : public IMoneyManager
{
private:
   string                  m_config_json;
   bool                    m_initialized;
    
   double                  m_fixed_lot;
   bool                    m_use_balance_based;
   bool                    m_use_equity_based;
   bool                    m_use_risk_percent;
   bool                    m_use_basket_risk_percent;
   bool                    m_use_full_margin;
   bool                    m_use_progressive_scaling;
   double                  m_base_risk_percent;
   double                  m_fixed_risk_amount;
   double                  m_balance_factor;
   double                  m_equity_factor;
   int                     m_progression_ladder[];
   double                  m_stop_loss_pips;

   void                   ParseConfig(const string config_json);
   double                 CalculateFixedLot(const SMoneyInput &input) const;
   double                 CalculateBalanceBasedLot(const SMoneyInput &input) const;
   double                 CalculateEquityBasedLot(const SMoneyInput &input) const;
   double                 CalculateRiskPercentLot(const SMoneyInput &input, const double tick_value, const double tick_size) const;
   double                 CalculateBasketRiskLot(const SMoneyInput &input, const double tick_value, const double tick_size) const;
   double                 CalculateFullMarginLot(const SMoneyInput &input, const double margin_rate) const;
   double                 ApplyProgressiveScaling(const double base_lot, const int add_entry_number) const;
   bool                   IsLotValid(const double lot, const double min_lot, const double max_lot, const double lot_step) const;

public:
   CMoneyManager();
   virtual ~CMoneyManager();
    
   virtual bool OnInit(const string config_json);
   virtual void OnDeinit();
    
   virtual SMoneyResult CalculateLot(const SMoneyInput &input);
   virtual bool ValidateLot(const double lot, const double min_lot, const double max_lot, const double lot_step);
   virtual string GetDiagnostics();
    
   virtual void LoadParameters(const string config_json);
};

//+------------------------------------------------------------------+
//| CMoneyManager Implementation                                     |
//+------------------------------------------------------------------+
CMoneyManager::CMoneyManager() : m_initialized(false),
   m_fixed_lot(0.1),
   m_use_balance_based(false),
   m_use_equity_based(false),
   m_use_risk_percent(false),
   m_use_basket_risk_percent(false),
   m_use_full_margin(false),
   m_use_progressive_scaling(false),
   m_base_risk_percent(1.0),
   m_fixed_risk_amount(0.0),
   m_balance_factor(0.01),
   m_equity_factor(0.01),
   m_stop_loss_pips(0.0)
{
   ArrayFree(m_progression_ladder);
}

CMoneyManager::~CMoneyManager()
{
   OnDeinit();
}

void CMoneyManager::ParseConfig(const string config_json)
{
   m_fixed_lot = 0.1;
   m_use_balance_based = false;
   m_use_equity_based = false;
   m_use_risk_percent = false;
   m_use_basket_risk_percent = false;
   m_use_full_margin = false;
   m_use_progressive_scaling = false;
   m_base_risk_percent = 1.0;
   m_fixed_risk_amount = 0.0;
   m_balance_factor = 0.01;
   m_equity_factor = 0.01;
   m_stop_loss_pips = 0.0;
   ArrayFree(m_progression_ladder);
    
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
        
      if(key == "fixed_lot")
         m_fixed_lot = StringToDouble(value);
      else if(key == "use_balance_based")
         m_use_balance_based = (value == "1" || value == "true");
      else if(key == "use_equity_based")
         m_use_equity_based = (value == "1" || value == "true");
      else if(key == "use_risk_percent")
         m_use_risk_percent = (value == "1" || value == "true");
      else if(key == "use_basket_risk_percent")
         m_use_basket_risk_percent = (value == "1" || value == "true");
      else if(key == "use_full_margin")
         m_use_full_margin = (value == "1" || value == "true");
      else if(key == "use_progressive_scaling")
         m_use_progressive_scaling = (value == "1" || value == "true");
      else if(key == "base_risk_percent")
         m_base_risk_percent = StringToDouble(value);
      else if(key == "fixed_risk_amount")
         m_fixed_risk_amount = StringToDouble(value);
      else if(key == "balance_factor")
         m_balance_factor = StringToDouble(value);
      else if(key == "equity_factor")
         m_equity_factor = StringToDouble(value);
      else if(key == "stop_loss_pips")
         m_stop_loss_pips = StringToDouble(value);
      else if(key == "progression_ladder")
      {
         string ladder[];
         StringSplit(value, ',', ladder);
         int count = ArraySize(ladder);
         ArrayFree(m_progression_ladder);
         if(count > 0)
         {
            ArrayResize(m_progression_ladder, count);
            for(int j = 0; j < count; j++)
               m_progression_ladder[j] = StringToInteger(StringTrim(ladder[j]));
         }
      }
   }
}

bool CMoneyManager::OnInit(const string config_json)
{
   m_config_json = config_json;
   m_initialized = true;
   ParseConfig(config_json);
   return true;
}

void CMoneyManager::OnDeinit()
{
   m_initialized = false;
   ArrayFree(m_progression_ladder);
}

void CMoneyManager::LoadParameters(const string config_json)
{
   m_config_json = config_json;
   ParseConfig(config_json);
}

double CMoneyManager::CalculateFixedLot(const SMoneyInput &input) const
{
   return m_fixed_lot;
}

double CMoneyManager::CalculateBalanceBasedLot(const SMoneyInput &input) const
{
   if(input.balance <= 0.0) return 0.0;
    
   double lot = (input.balance * m_balance_factor) / 100.0;
   if(lot <= 0.0) lot = m_fixed_lot;
    
   return lot;
}

double CMoneyManager::CalculateEquityBasedLot(const SMoneyInput &input) const
{
   if(input.equity <= 0.0) return 0.0;
    
   double lot = (input.equity * m_equity_factor) / 100.0;
   if(lot <= 0.0) lot = m_fixed_lot;
    
   return lot;
}

double CMoneyManager::CalculateRiskPercentLot(const SMoneyInput &input, const double tick_value, const double tick_size) const
{
   if(input.stop_loss_pips <= 0.0 || tick_size <= 0.0 || tick_value <= 0.0)
      return m_fixed_lot;
    
   double risk_amount = 0.0;
   if(m_fixed_risk_amount > 0.0)
   {
      risk_amount = m_fixed_risk_amount;
   }
   else
   {
      risk_amount = input.balance * (m_base_risk_percent / 100.0);
   }
    
   double sl_currency = input.stop_loss_pips * tick_value * (tick_size / 0.0001);
   if(sl_currency <= 0.0)
      return m_fixed_lot;
    
   double lot = risk_amount / sl_currency;
   if(lot <= 0.0) lot = m_fixed_lot;
    
   return lot;
}

double CMoneyManager::CalculateBasketRiskLot(const SMoneyInput &input, const double tick_value, const double tick_size) const
{
   if(input.stop_loss_pips <= 0.0 || tick_size <= 0.0 || tick_value <= 0.0)
      return m_fixed_lot;
    
   double risk_amount = input.balance * (m_base_risk_percent / 100.0);
    
   double sl_currency = input.stop_loss_pips * tick_value * (tick_size / 0.0001);
   if(sl_currency <= 0.0)
      return m_fixed_lot;
    
   double lot = risk_amount / sl_currency;
   if(lot <= 0.0) lot = m_fixed_lot;
    
   return lot;
}

double CMoneyManager::CalculateFullMarginLot(const SMoneyInput &input, const double margin_rate) const
{
   if(input.free_margin <= 0.0 || margin_rate <= 0.0)
      return m_fixed_lot;
    
   double lot = input.free_margin / margin_rate;
   if(lot <= 0.0) lot = m_fixed_lot;
    
   return lot;
}

double CMoneyManager::ApplyProgressiveScaling(const double base_lot, const int add_entry_number) const
{
   if(!m_use_progressive_scaling)
      return base_lot;
    
   int ladder_size = ArraySize(m_progression_ladder);
   if(ladder_size <= 0)
      return base_lot;
    
   int idx = add_entry_number - 1;
   if(idx < 0) idx = 0;
   if(idx >= ladder_size) idx = ladder_size - 1;
    
   double multiplier = m_progression_ladder[idx] / 100.0;
   if(multiplier < 0.0) multiplier = 0.0;
    
   return base_lot * multiplier;
}

bool CMoneyManager::IsLotValid(const double lot, const double min_lot, const double max_lot, const double lot_step) const
{
   if(lot < min_lot) return false;
   if(lot > max_lot) return false;
    
   double remainder = (lot - min_lot) / lot_step;
   remainder = remainder - MathFloor(remainder);
   if(remainder > 1e-10) return false;
    
   return true;
}

SMoneyResult CMoneyManager::CalculateLot(const SMoneyInput &input)
{
   SMoneyResult result;
   ZeroMemory(result);
    
   if(!m_initialized)
   {
      result.suggested_lot = 0.0;
      result.allowed = false;
      result.rejection_reason = "money manager not initialized";
      return result;
   }
    
   double lot = 0.0;
    
   if(m_use_basket_risk_percent)
   {
      double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      lot = CalculateBasketRiskLot(input, tick_value, tick_size);
   }
   else if(m_use_risk_percent)
   {
      double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      lot = CalculateRiskPercentLot(input, tick_value, tick_size);
   }
   else if(m_use_balance_based)
   {
      lot = CalculateBalanceBasedLot(input);
   }
   else if(m_use_equity_based)
   {
      lot = CalculateEquityBasedLot(input);
   }
   else if(m_use_full_margin)
   {
      double margin_rate = SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_INITIAL);
      lot = CalculateFullMarginLot(input, margin_rate);
   }
   else
   {
      lot = CalculateFixedLot(input);
   }
    
   if(input.is_add_on && m_use_progressive_scaling)
   {
      lot = ApplyProgressiveScaling(lot, input.add_entry_number);
   }
    
   if(lot <= 0.0)
   {
      result.suggested_lot = 0.0;
      result.allowed = false;
      result.rejection_reason = "calculated lot is zero or negative";
      return result;
   }
    
   result.suggested_lot = lot;
   result.allowed = true;
   result.rejection_reason = "";
    
   return result;
}

bool CMoneyManager::ValidateLot(const double lot, const double min_lot, const double max_lot, const double lot_step)
{
   if(lot < min_lot) return false;
   if(lot > max_lot) return false;
    
   double remainder = (lot - min_lot) / lot_step;
   remainder = remainder - MathFloor(remainder);
   if(remainder > 1e-10) return false;
    
   return true;
}

string CMoneyManager::GetDiagnostics()
{
   return StringConcatenate("money: fixed=", DoubleToString(m_fixed_lot), " balance_based=", (m_use_balance_based ? "yes" : "no"), " risk_pct=", DoubleToString(m_base_risk_percent), " progressive=", (m_use_progressive_scaling ? "yes" : "no"));
}

#endif // MONEYMANAGER_MQH_GUARD
