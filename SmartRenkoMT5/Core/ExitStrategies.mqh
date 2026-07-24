//+------------------------------------------------------------------+
//| Exit Strategies - Concrete Implementations                        |
//+------------------------------------------------------------------+
#ifndef EXITSTRATEGIES_MQH_GUARD
#define EXITSTRATEGIES_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"
#include "TrailingManager.mqh"

//+------------------------------------------------------------------+
//| Basket Trailing Exit Strategy                                     |
//+------------------------------------------------------------------+
class CBasketTrailingExitStrategy : public IExitStrategy
{
private:
   string                  m_symbol;
   long                    m_magic_number;
   bool                    m_initialized;
   string                  m_name;
   ITrailingManager*       m_trailing_manager;

public:
   CBasketTrailingExitStrategy();
   virtual ~CBasketTrailingExitStrategy();
   
   virtual bool OnInit(const string symbol, const long magic_number);
   virtual void OnDeinit();
   virtual void LoadParameters(const string params);
   
   virtual bool EvaluateClose(const SBasket &basket, const SPosition &position, const double current_profit);
   virtual bool EvaluateReduce(const SBasket &basket, const SPosition &position, const double current_profit);
   virtual string GetDiagnostics();
   virtual string GetName();
   
   void SetTrailingManager(ITrailingManager* manager) { m_trailing_manager = manager; }
};

//+------------------------------------------------------------------+
//| CBasketTrailingExitStrategy Implementation                        |
//+------------------------------------------------------------------+
CBasketTrailingExitStrategy::CBasketTrailingExitStrategy() : m_symbol(""),
   m_magic_number(0),
   m_initialized(false),
   m_name("BasketTrailingExit"),
   m_trailing_manager(NULL)
{
}

CBasketTrailingExitStrategy::~CBasketTrailingExitStrategy()
{
   OnDeinit();
}

bool CBasketTrailingExitStrategy::OnInit(const string symbol, const long magic_number)
{
   m_symbol = symbol;
   m_magic_number = magic_number;
   m_initialized = true;
   return true;
}

void CBasketTrailingExitStrategy::OnDeinit()
{
   m_initialized = false;
   m_trailing_manager = NULL;
}

void CBasketTrailingExitStrategy::LoadParameters(const string params)
{
}

bool CBasketTrailingExitStrategy::EvaluateClose(const SBasket &basket, const SPosition &position, const double current_profit)
{
   if(!m_initialized) return false;
   if(m_trailing_manager == NULL) return false;
   
   if(basket.state != BASKET_STATE_ACTIVE && basket.state != BASKET_STATE_TRAILING_ACTIVE)
      return false;
   
   if(m_trailing_manager.Evaluate(current_profit))
      return true;
   
   return false;
}

bool CBasketTrailingExitStrategy::EvaluateReduce(const SBasket &basket, const SPosition &position, const double current_profit)
{
   return false;
}

string CBasketTrailingExitStrategy::GetDiagnostics()
{
   return StringConcatenate("name=", m_name, " symbol=", m_symbol, " initialized=", (m_initialized ? "yes" : "no"));
}

string CBasketTrailingExitStrategy::GetName()
{
   return m_name;
}

//+------------------------------------------------------------------+
//| Individual Position Exit Strategy                                |
//+------------------------------------------------------------------+
class CIndividualPositionExitStrategy : public IExitStrategy
{
private:
   string                  m_symbol;
   long                    m_magic_number;
   bool                    m_initialized;
   string                  m_name;
   double                  m_fixed_profit_threshold;
   double                  m_fixed_loss_threshold;

public:
   CIndividualPositionExitStrategy();
   virtual ~CIndividualPositionExitStrategy();
   
   virtual bool OnInit(const string symbol, const long magic_number);
   virtual void OnDeinit();
   virtual void LoadParameters(const string params);
   
   virtual bool EvaluateClose(const SBasket &basket, const SPosition &position, const double current_profit);
   virtual bool EvaluateReduce(const SBasket &basket, const SPosition &position, const double current_profit);
   virtual string GetDiagnostics();
   virtual string GetName();
};

//+------------------------------------------------------------------+
//| CIndividualPositionExitStrategy Implementation                   |
//+------------------------------------------------------------------+
CIndividualPositionExitStrategy::CIndividualPositionExitStrategy() : m_symbol(""),
   m_magic_number(0),
   m_initialized(false),
   m_name("IndividualPositionExit"),
   m_fixed_profit_threshold(0.0),
   m_fixed_loss_threshold(0.0)
{
}

CIndividualPositionExitStrategy::~CIndividualPositionExitStrategy()
{
   OnDeinit();
}

bool CIndividualPositionExitStrategy::OnInit(const string symbol, const long magic_number)
{
   m_symbol = symbol;
   m_magic_number = magic_number;
   m_initialized = true;
   return true;
}

void CIndividualPositionExitStrategy::OnDeinit()
{
   m_initialized = false;
}

void CIndividualPositionExitStrategy::LoadParameters(const string params)
{
   if(params == "" || params == "0")
      return;
   
   string parts[];
   StringSplit(params, ';', parts);
   
   for(int i = 0; i < ArraySize(parts); i++)
   {
      if(parts[i] == "") continue;
      
      string kv[];
      StringSplit(parts[i], '=', kv);
      
      if(ArraySize(kv) < 2) continue;
      
      string key = StringTrim(kv[0]);
      string value = StringTrim(kv[1]);
      
      if(key == "fixed_profit_threshold")
         m_fixed_profit_threshold = StringToDouble(value);
      else if(key == "fixed_loss_threshold")
         m_fixed_loss_threshold = StringToDouble(value);
   }
}

bool CIndividualPositionExitStrategy::EvaluateClose(const SBasket &basket, const SPosition &position, const double current_profit)
{
   if(!m_initialized) return false;
   if(!position.is_active) return false;
   
   if(m_fixed_profit_threshold > 0.0 && current_profit >= m_fixed_profit_threshold)
      return true;
   
   if(m_fixed_loss_threshold < 0.0 && current_profit <= m_fixed_loss_threshold)
      return true;
   
   return false;
}

bool CIndividualPositionExitStrategy::EvaluateReduce(const SBasket &basket, const SPosition &position, const double current_profit)
{
   return false;
}

string CIndividualPositionExitStrategy::GetDiagnostics()
{
   return StringConcatenate("name=", m_name, " symbol=", m_symbol, " profit_thresh=", DoubleToString(m_fixed_profit_threshold), " loss_thresh=", DoubleToString(m_fixed_loss_threshold));
}

string CIndividualPositionExitStrategy::GetName()
{
   return m_name;
}

#endif // EXITSTRATEGIES_MQH_GUARD
