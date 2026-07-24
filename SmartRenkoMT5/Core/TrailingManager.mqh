//+------------------------------------------------------------------+
//| Trailing Manager - Concrete Placeholder                          |
//+------------------------------------------------------------------+
#ifndef TRAILINGMANAGER_MQH_GUARD
#define TRAILINGMANAGER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CTrailingManager : public ITrailingManager
{
private:
   string                  m_basket_id;
   double                  m_start_balance;
   double                  m_threshold;
   double                  m_trail_amount;
   bool                    m_active;
   double                  m_peak_profit;
   string                  m_config_json;
   bool                    m_initialized;

public:
   CTrailingManager();
   virtual ~CTrailingManager();
   
   virtual bool OnInit(const string basket_id, const double start_balance, const double threshold, const double trail_amount, const string config_json);
   virtual void OnDeinit();
   
   virtual bool Evaluate(const double current_floating_profit);
   virtual bool IsActive();
   virtual double GetPeakProfit();
   virtual bool RestoreState(const double peak_profit, const bool activated);
   virtual string GetDiagnostics();
};

//+------------------------------------------------------------------+
//| CTrailingManager Implementation                                  |
//+------------------------------------------------------------------+
CTrailingManager::CTrailingManager() : m_basket_id(""),
   m_start_balance(0.0),
   m_threshold(0.0),
   m_trail_amount(0.0),
   m_active(false),
   m_peak_profit(0.0),
   m_initialized(false)
{
}

CTrailingManager::~CTrailingManager()
{
   OnDeinit();
}

bool CTrailingManager::OnInit(const string basket_id, const double start_balance, const double threshold, const double trail_amount, const string config_json)
{
   m_basket_id = basket_id;
   m_start_balance = start_balance;
   m_threshold = threshold;
   m_trail_amount = trail_amount;
   m_config_json = config_json;
   m_active = false;
   m_peak_profit = 0.0;
   m_initialized = true;
   return true;
}

void CTrailingManager::OnDeinit()
{
   m_initialized = false;
}

bool CTrailingManager::Evaluate(const double current_floating_profit)
{
   if(!m_initialized) return false;
   
   if(!m_active)
   {
      if(current_floating_profit >= m_threshold)
      {
         m_active = true;
         m_peak_profit = current_floating_profit;
      }
      return false;
   }
   
   if(current_floating_profit > m_peak_profit)
      m_peak_profit = current_floating_profit;
   
   if(current_floating_profit <= (m_peak_profit - m_trail_amount))
      return true;
   
   return false;
}

bool CTrailingManager::IsActive()
{
   return m_active;
}

double CTrailingManager::GetPeakProfit()
{
   return m_peak_profit;
}

bool CTrailingManager::RestoreState(const double peak_profit, const bool activated)
{
   m_peak_profit = peak_profit;
   m_active = activated;
   return true;
}

string CTrailingManager::GetDiagnostics()
{
   return StringConcatenate("trailing: active=", (m_active ? "yes" : "no"), " peak=", DoubleToString(m_peak_profit));
}

#endif // TRAILINGMANAGER_MQH_GUARD
