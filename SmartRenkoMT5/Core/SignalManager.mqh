//+------------------------------------------------------------------+
//| Signal Manager - Concrete Placeholder                            |
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
};

//+------------------------------------------------------------------+
//| CSignalManager Implementation                                    |
//+------------------------------------------------------------------+
CSignalManager::CSignalManager() : m_magic_number(0),
   m_entry_count(0),
   m_exit_count(0)
{
   ZeroMemory(m_last_signal);
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
   ArrayFree(m_entry_strategies);
   ArrayFree(m_exit_strategies);
   return true;
}

void CSignalManager::OnDeinit()
{
   m_entry_count = 0;
   m_exit_count = 0;
   ArrayFree(m_entry_strategies);
   ArrayFree(m_exit_strategies);
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
   final_signal.metadata = "no strategies registered";
   return true;
}

bool CSignalManager::NormalizeSignal(SSignal &signal)
{
   if(signal.strength > 1.0) signal.strength = 1.0;
   if(signal.strength < 0.0) signal.strength = 0.0;
   return true;
}

string CSignalManager::GetDiagnostics()
{
   return StringConcatenate("entry_strategies=", IntegerToString(m_entry_count), " exit_strategies=", IntegerToString(m_exit_count));
}

#endif // SIGNALMANAGER_MQH_GUARD
