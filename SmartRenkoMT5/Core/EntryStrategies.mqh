//+------------------------------------------------------------------+
//| Entry Strategies - Concrete Implementations                       |
//+------------------------------------------------------------------+
#ifndef ENTRYSTRATEGIES_MQH_GUARD
#define ENTRYSTRATEGIES_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"
#include "RenkoDataProvider.mqh"

//+------------------------------------------------------------------+
//| Renko Continuation Entry Strategy                                |
//+------------------------------------------------------------------+
class CRenkoContinuationEntryStrategy : public IEntryStrategy
{
private:
   string                  m_symbol;
   long                    m_magic_number;
   bool                    m_initialized;
   string                  m_name;
   IRenkoDataProvider*     m_renko_provider;
   int                     m_min_continuation_bricks;
   int                     m_lookback_bricks;
   double                  m_min_strength;
   bool                    m_require_no_reversal;
   ENUM_TRADING_MODE       m_allowed_modes;

public:
   CRenkoContinuationEntryStrategy();
   virtual ~CRenkoContinuationEntryStrategy();
   
   virtual bool OnInit(const string symbol, const long magic_number);
   virtual void OnDeinit();
   virtual void LoadParameters(const string params);
   
   virtual bool IsEligible(const SRenkoBrick &brick, const ENUM_TRADING_MODE mode);
   virtual bool GenerateSignal(SSignal &signal, const SRenkoBrick &brick);
   virtual string GetDiagnostics();
   virtual string GetName();
   
   void SetRenkoProvider(IRenkoDataProvider* provider) { m_renko_provider = provider; }
};

//+------------------------------------------------------------------+
//| CRenkoContinuationEntryStrategy Implementation                   |
//+------------------------------------------------------------------+
CRenkoContinuationEntryStrategy::CRenkoContinuationEntryStrategy() : m_symbol(""),
   m_magic_number(0),
   m_initialized(false),
   m_name("RenkoContinuation"),
   m_renko_provider(NULL),
   m_min_continuation_bricks(2),
   m_lookback_bricks(10),
   m_min_strength(0.5),
   m_require_no_reversal(true),
   m_allowed_modes(TRADING_MODE_FULL_AUTO)
{
}

CRenkoContinuationEntryStrategy::~CRenkoContinuationEntryStrategy()
{
   OnDeinit();
}

bool CRenkoContinuationEntryStrategy::OnInit(const string symbol, const long magic_number)
{
   m_symbol = symbol;
   m_magic_number = magic_number;
   m_initialized = true;
   return true;
}

void CRenkoContinuationEntryStrategy::OnDeinit()
{
   m_initialized = false;
   m_renko_provider = NULL;
}

void CRenkoContinuationEntryStrategy::LoadParameters(const string params)
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
      
      if(key == "min_continuation_bricks")
         m_min_continuation_bricks = StringToInteger(value);
      else if(key == "lookback_bricks")
         m_lookback_bricks = StringToInteger(value);
      else if(key == "min_strength")
         m_min_strength = StringToDouble(value);
      else if(key == "require_no_reversal")
         m_require_no_reversal = (value == "1" || value == "true");
      else if(key == "allowed_modes")
         m_allowed_modes = (ENUM_TRADING_MODE)StringToInteger(value);
   }
}

bool CRenkoContinuationEntryStrategy::IsEligible(const SRenkoBrick &brick, const ENUM_TRADING_MODE mode)
{
   if(!m_initialized) return false;
   if(m_renko_provider == NULL) return false;
   if(brick.brick_size <= 0.0) return false;
   
   if((m_allowed_modes & mode) == 0) return false;
   
   if(!m_renko_provider.IsFresh(60))
      return false;
   
   SRenkoBrick history[];
   if(!m_renko_provider.GetHistoricalContext(m_lookback_bricks, history))
      return false;
   
   int count = ArraySize(history);
   if(count < m_min_continuation_bricks)
      return false;
   
   if(m_require_no_reversal)
   {
      for(int i = count - m_min_continuation_bricks; i < count; i++)
      {
         if(history[i].is_bullish != brick.is_bullish)
            return false;
      }
   }
   
   return true;
}

bool CRenkoContinuationEntryStrategy::GenerateSignal(SSignal &signal, const SRenkoBrick &brick)
{
   ZeroMemory(signal);
   
   if(!IsEligible(brick, m_allowed_modes))
   {
      signal.direction = SIGNAL_DIRECTION_NONE;
      signal.strength = 0.0;
      return false;
   }
   
   signal.direction = brick.is_bullish ? SIGNAL_DIRECTION_BUY : SIGNAL_DIRECTION_SELL;
   signal.strength = 1.0;
   signal.source = SIGNAL_SOURCE_ENTRY_STRATEGY;
   signal.brick_index = brick.brick_index;
   signal.signal_time = TimeCurrent();
   signal.metadata = StringConcatenate("continuation_bricks=", IntegerToString(m_min_continuation_bricks), ";lookback=", IntegerToString(m_lookback_bricks));
   
   return true;
}

string CRenkoContinuationEntryStrategy::GetDiagnostics()
{
   return StringConcatenate("name=", m_name, " symbol=", m_symbol, " min_cont=", IntegerToString(m_min_continuation_bricks), " lookback=", IntegerToString(m_lookback_bricks), " initialized=", (m_initialized ? "yes" : "no"));
}

string CRenkoContinuationEntryStrategy::GetName()
{
   return m_name;
}

//+------------------------------------------------------------------+
//| Renko Reversal Entry Strategy                                    |
//+------------------------------------------------------------------+
class CRenkoReversalEntryStrategy : public IEntryStrategy
{
private:
   string                  m_symbol;
   long                    m_magic_number;
   bool                    m_initialized;
   string                  m_name;
   IRenkoDataProvider*     m_renko_provider;
   int                     m_min_reversal_bricks;
   double                  m_min_strength;
   ENUM_TRADING_MODE       m_allowed_modes;

public:
   CRenkoReversalEntryStrategy();
   virtual ~CRenkoReversalEntryStrategy();
   
   virtual bool OnInit(const string symbol, const long magic_number);
   virtual void OnDeinit();
   virtual void LoadParameters(const string params);
   
   virtual bool IsEligible(const SRenkoBrick &brick, const ENUM_TRADING_MODE mode);
   virtual bool GenerateSignal(SSignal &signal, const SRenkoBrick &brick);
   virtual string GetDiagnostics();
   virtual string GetName();
   
   void SetRenkoProvider(IRenkoDataProvider* provider) { m_renko_provider = provider; }
};

//+------------------------------------------------------------------+
//| CRenkoReversalEntryStrategy Implementation                       |
//+------------------------------------------------------------------+
CRenkoReversalEntryStrategy::CRenkoReversalEntryStrategy() : m_symbol(""),
   m_magic_number(0),
   m_initialized(false),
   m_name("RenkoReversal"),
   m_renko_provider(NULL),
   m_min_reversal_bricks(1),
   m_min_strength(0.7),
   m_allowed_modes(TRADING_MODE_FULL_AUTO)
{
}

CRenkoReversalEntryStrategy::~CRenkoReversalEntryStrategy()
{
   OnDeinit();
}

bool CRenkoReversalEntryStrategy::OnInit(const string symbol, const long magic_number)
{
   m_symbol = symbol;
   m_magic_number = magic_number;
   m_initialized = true;
   return true;
}

void CRenkoReversalEntryStrategy::OnDeinit()
{
   m_initialized = false;
   m_renko_provider = NULL;
}

void CRenkoReversalEntryStrategy::LoadParameters(const string params)
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
      
      if(key == "min_reversal_bricks")
         m_min_reversal_bricks = StringToInteger(value);
      else if(key == "min_strength")
         m_min_strength = StringToDouble(value);
      else if(key == "allowed_modes")
         m_allowed_modes = (ENUM_TRADING_MODE)StringToInteger(value);
   }
}

bool CRenkoReversalEntryStrategy::IsEligible(const SRenkoBrick &brick, const ENUM_TRADING_MODE mode)
{
   if(!m_initialized) return false;
   if(m_renko_provider == NULL) return false;
   if(brick.brick_size <= 0.0) return false;
   
   if((m_allowed_modes & mode) == 0) return false;
   
   if(!m_renko_provider.IsFresh(60))
      return false;
   
   if(!m_renko_provider.IsReversal())
      return false;
   
   return true;
}

bool CRenkoReversalEntryStrategy::GenerateSignal(SSignal &signal, const SRenkoBrick &brick)
{
   ZeroMemory(signal);
   
   if(!IsEligible(brick, m_allowed_modes))
   {
      signal.direction = SIGNAL_DIRECTION_NONE;
      signal.strength = 0.0;
      return false;
   }
   
   signal.direction = brick.is_bullish ? SIGNAL_DIRECTION_BUY : SIGNAL_DIRECTION_SELL;
   signal.strength = m_min_strength;
   signal.source = SIGNAL_SOURCE_ENTRY_STRATEGY;
   signal.brick_index = brick.brick_index;
   signal.signal_time = TimeCurrent();
   signal.metadata = StringConcatenate("reversal_bricks=", IntegerToString(m_min_reversal_bricks));
   
   return true;
}

string CRenkoReversalEntryStrategy::GetDiagnostics()
{
   return StringConcatenate("name=", m_name, " symbol=", m_symbol, " min_rev=", IntegerToString(m_min_reversal_bricks), " initialized=", (m_initialized ? "yes" : "no"));
}

string CRenkoReversalEntryStrategy::GetName()
{
   return m_name;
}

#endif // ENTRYSTRATEGIES_MQH_GUARD
