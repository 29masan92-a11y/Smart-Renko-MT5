//+------------------------------------------------------------------+
//| Signal Manager - Concrete Implementation                          |
//+------------------------------------------------------------------+
#ifndef SIGNALMANAGER_MQH_GUARD
#define SIGNALMANAGER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CSignalManager : public ISignalManager
{
private:
   long                    m_magic_number;
   IEntryStrategy*         m_entry_strategies[];
   int                     m_entry_count;
   IExitStrategy*          m_exit_strategies[];
   int                     m_exit_count;
   SSignal                 m_last_signal;
   SSignal                 m_last_exit_signal;
   bool                    m_initialized;

public:
   CSignalManager();
   virtual ~CSignalManager();
   
   virtual bool OnInit(const long magic_number);
   virtual void OnDeinit();
   
   virtual bool RegisterEntryStrategy(IEntryStrategy* strategy);
   virtual bool RegisterExitStrategy(IExitStrategy* strategy);
   virtual bool AggregateSignals(SSignal &final_signal);
   virtual bool NormalizeSignal(SSignal &signal);
   virtual string GetDiagnostics();
   
   bool AggregateExitSignals(SSignal &exit_signal, const SBasket &basket, const SPosition &position, const double current_profit);
};

//+------------------------------------------------------------------+
//| CSignalManager Implementation                                    |
//+------------------------------------------------------------------+
CSignalManager::CSignalManager() : m_magic_number(0),
   m_entry_count(0),
   m_exit_count(0),
   m_initialized(false)
{
   ZeroMemory(m_last_signal);
   ZeroMemory(m_last_exit_signal);
}

CSignalManager::~CSignalManager()
{
   OnDeinit();
}

bool CSignalManager::OnInit(const long magic_number)
{
   m_magic_number = magic_number;
   m_entry_count = 0;
   m_exit_count = 0;
   m_initialized = true;
   ArrayFree(m_entry_strategies);
   ArrayFree(m_exit_strategies);
   ZeroMemory(m_last_signal);
   ZeroMemory(m_last_exit_signal);
   return true;
}

void CSignalManager::OnDeinit()
{
   m_entry_count = 0;
   m_exit_count = 0;
   m_initialized = false;
   ArrayFree(m_entry_strategies);
   ArrayFree(m_exit_strategies);
   ZeroMemory(m_last_signal);
   ZeroMemory(m_last_exit_signal);
}

bool CSignalManager::RegisterEntryStrategy(IEntryStrategy* strategy)
{
   if(strategy == NULL) return false;
   int new_size = m_entry_count + 1;
   ArrayResize(m_entry_strategies, new_size);
   m_entry_strategies[m_entry_count] = strategy;
   m_entry_count++;
   return true;
}

bool CSignalManager::RegisterExitStrategy(IExitStrategy* strategy)
{
   if(strategy == NULL) return false;
   int new_size = m_exit_count + 1;
   ArrayResize(m_exit_strategies, new_size);
   m_exit_strategies[m_exit_count] = strategy;
   m_exit_count++;
   return true;
}

bool CSignalManager::AggregateSignals(SSignal &final_signal)
{
   ZeroMemory(final_signal);
   final_signal.direction = SIGNAL_DIRECTION_NONE;
   final_signal.strength = 0.0;
   final_signal.source = SIGNAL_SOURCE_ENTRY_STRATEGY;
   final_signal.brick_index = 0;
   final_signal.signal_time = TimeCurrent();
   final_signal.metadata = "no entry strategies registered";
   
   if(m_entry_count <= 0)
      return false;
   
   SSignal best_signal;
   ZeroMemory(best_signal);
   best_signal.strength = -1.0;
   
   bool found = false;
   
   for(int i = 0; i < m_entry_count; i++)
   {
      if(m_entry_strategies[i] == NULL) continue;
      
      SRenkoBrick brick;
      if(!m_entry_strategies[i]->IsEligible(brick, TRADING_MODE_FULL_AUTO))
         continue;
      
      SSignal signal;
      ZeroMemory(signal);
      if(m_entry_strategies[i]->GenerateSignal(signal, brick))
      {
         if(signal.direction != SIGNAL_DIRECTION_NONE && signal.strength > best_signal.strength)
         {
            best_signal = signal;
            found = true;
         }
      }
   }
   
   if(!found)
   {
      final_signal.metadata = "no eligible signals";
      return false;
   }
   
   final_signal = best_signal;
   NormalizeSignal(final_signal);
   m_last_signal = final_signal;
   
   return true;
}

bool CSignalManager::AggregateExitSignals(SSignal &exit_signal, const SBasket &basket, const SPosition &position, const double current_profit)
{
   ZeroMemory(exit_signal);
   exit_signal.direction = SIGNAL_DIRECTION_NONE;
   exit_signal.strength = 0.0;
   exit_signal.source = SIGNAL_SOURCE_EXIT_STRATEGY;
   exit_signal.brick_index = 0;
   exit_signal.signal_time = TimeCurrent();
   exit_signal.metadata = "no exit strategies registered";
   
   if(m_exit_count <= 0)
      return false;
   
   for(int i = 0; i < m_exit_count; i++)
   {
      if(m_exit_strategies[i] == NULL) continue;
      
      bool should_close = m_exit_strategies[i]->EvaluateClose(basket, position, current_profit);
      if(should_close)
      {
         exit_signal.direction = SIGNAL_DIRECTION_NONE;
         exit_signal.strength = 1.0;
         exit_signal.source = SIGNAL_SOURCE_EXIT_STRATEGY;
         exit_signal.brick_index = position.position_ticket;
         exit_signal.signal_time = TimeCurrent();
         exit_signal.metadata = StringConcatenate("exit_source=", m_exit_strategies[i]->GetName());
         m_last_exit_signal = exit_signal;
         return true;
      }
   }
   
   exit_signal.metadata = "no exit signals";
   return false;
}

bool CSignalManager::NormalizeSignal(SSignal &signal)
{
   if(signal.strength > 1.0) signal.strength = 1.0;
   if(signal.strength < 0.0) signal.strength = 0.0;
   if(signal.direction == SIGNAL_DIRECTION_NONE)
      signal.strength = 0.0;
   return true;
}

string CSignalManager::GetDiagnostics()
{
   return StringConcatenate("entry_strategies=", IntegerToString(m_entry_count), " exit_strategies=", IntegerToString(m_exit_count), " last_signal_dir=", EnumToString(m_last_signal.direction), " last_signal_str=", DoubleToString(m_last_signal.strength));
}

#endif // SIGNALMANAGER_MQH_GUARD
