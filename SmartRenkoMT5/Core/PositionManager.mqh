//+------------------------------------------------------------------+
//| Position Manager - Concrete Implementation                       |
//+------------------------------------------------------------------+
#ifndef POSITIONMANAGER_MQH_GUARD
#define POSITIONMANAGER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CPositionManager : public IPositionManager
{
private:
   string                  m_symbol;
   long                    m_magic_number;
   IExecutionAdapter*      m_execution_adapter;
   SPosition               m_positions[];
   int                     m_position_count;

   int FindPositionIndex(const ulong ticket);

public:
   CPositionManager();
   virtual ~CPositionManager();
   
   virtual bool OnInit(const string symbol, const long magic_number, IExecutionAdapter* adapter);
   virtual void OnDeinit();
   
   virtual bool OpenPosition(const string basket_id, const ENUM_POSITION_TYPE type, const double volume, const double price, const double sl, const double tp, const string comment);
   virtual bool ClosePosition(const ulong ticket);
   virtual bool CloseAllPositions(const string basket_id);
   virtual bool GetPositionsByBasket(const string basket_id, SPosition &positions[], int &count);
   virtual bool GetOpenPositions(SPosition &positions[], int &count);
   virtual bool UpdatePositionProfit();
   virtual double GetTotalProfit(const string basket_id = "");
   virtual int GetOpenPositionCount();
   virtual string GetDiagnostics();
};

//+------------------------------------------------------------------+
//| CPositionManager Implementation                                  |
//+------------------------------------------------------------------+
CPositionManager::CPositionManager() : m_symbol(""),
   m_magic_number(0),
   m_execution_adapter(NULL),
   m_position_count(0)
{
   ArrayFree(m_positions);
}

CPositionManager::~CPositionManager()
{
   OnDeinit();
}

bool CPositionManager::OnInit(const string symbol, const long magic_number, IExecutionAdapter* adapter)
{
   m_symbol = symbol;
   m_magic_number = magic_number;
   m_execution_adapter = adapter;
   m_position_count = 0;
   ArrayFree(m_positions);
   return true;
}

void CPositionManager::OnDeinit()
{
   m_execution_adapter = NULL;
   m_position_count = 0;
   ArrayFree(m_positions);
}

int CPositionManager::FindPositionIndex(const ulong ticket)
{
   for(int i = 0; i < m_position_count; i++)
   {
      if(m_positions[i].position_ticket == ticket)
         return i;
   }
   return -1;
}

bool CPositionManager::OpenPosition(const string basket_id, const ENUM_POSITION_TYPE type, const double volume, const double price, const double sl, const double tp, const string comment)
{
   if(m_execution_adapter == NULL)
   {
      Print("ERROR: PositionManager has no execution adapter");
      return false;
   }
   
   ENUM_BROKER_ORDER_TYPE order_type = (type == POSITION_TYPE_LONG) ? BROKER_ORDER_TYPE_BUY : BROKER_ORDER_TYPE_SELL;
   SExecutionResult result = m_execution_adapter.SendOrder(order_type, volume, price, sl, tp, comment);
   
   if(!result.success)
   {
      Print("ERROR: Failed to open position: ", result.error_message);
      return false;
   }
   
   SPosition new_pos;
   ZeroMemory(new_pos);
   new_pos.position_ticket = result.ticket;
   new_pos.symbol = m_symbol;
   new_pos.type = type;
   new_pos.volume = volume;
   new_pos.open_price = result.executed_price;
   new_pos.open_time = result.execution_time;
   new_pos.profit = 0.0;
   new_pos.commission = 0.0;
   new_pos.swap = 0.0;
   new_pos.magic_number = m_magic_number;
   new_pos.basket_id = basket_id;
   new_pos.is_active = true;
   new_pos.comment = comment;
   
   int new_size = m_position_count + 1;
   ArrayResize(m_positions, new_size);
   m_positions[m_position_count] = new_pos;
   m_position_count++;
   
   return true;
}

bool CPositionManager::ClosePosition(const ulong ticket)
{
   int idx = FindPositionIndex(ticket);
   if(idx < 0)
   {
      Print("ERROR: Position not found for ticket ", ticket);
      return false;
   }
   
   if(m_execution_adapter != NULL)
   {
      if(!m_execution_adapter.ClosePosition(ticket))
      {
         Print("ERROR: Failed to close position ", ticket);
         return false;
      }
   }
   
   m_positions[idx].is_active = false;
   return true;
}

bool CPositionManager::CloseAllPositions(const string basket_id)
{
   bool all_closed = true;
   
   for(int i = 0; i < m_position_count; i++)
   {
      if(m_positions[i].is_active && m_positions[i].basket_id == basket_id)
      {
         if(!ClosePosition(m_positions[i].position_ticket))
            all_closed = false;
      }
   }
   
   return all_closed;
}

bool CPositionManager::GetPositionsByBasket(const string basket_id, SPosition &positions[], int &count)
{
   count = 0;
   ArrayFree(positions);
   
   for(int i = 0; i < m_position_count; i++)
   {
      if(m_positions[i].basket_id == basket_id)
      {
         int new_size = count + 1;
         ArrayResize(positions, new_size);
         positions[count] = m_positions[i];
         count++;
      }
   }
   
   return (count > 0);
}

bool CPositionManager::GetOpenPositions(SPosition &positions[], int &count)
{
   count = 0;
   ArrayFree(positions);
   
   for(int i = 0; i < m_position_count; i++)
   {
      if(m_positions[i].is_active)
      {
         int new_size = count + 1;
         ArrayResize(positions, new_size);
         positions[count] = m_positions[i];
         count++;
      }
   }
   
   return true;
}

bool CPositionManager::UpdatePositionProfit()
{
   if(m_execution_adapter == NULL)
      return false;
   
   SPosition broker_positions[];
   int broker_count = 0;
   
   if(!m_execution_adapter.GetOpenPositions(broker_positions))
      return false;
   
   for(int i = 0; i < m_position_count; i++)
   {
      if(!m_positions[i].is_active)
         continue;
         
      for(int j = 0; j < broker_count; j++)
      {
         if(broker_positions[j].position_ticket == m_positions[i].position_ticket)
         {
            m_positions[i].profit = broker_positions[j].profit;
            m_positions[i].commission = broker_positions[j].commission;
            m_positions[i].swap = broker_positions[j].swap;
            break;
         }
      }
   }
   
   return true;
}

double CPositionManager::GetTotalProfit(const string basket_id = "")
{
   double total = 0.0;
   
   for(int i = 0; i < m_position_count; i++)
   {
      if(!m_positions[i].is_active)
         continue;
         
      if(basket_id == "" || m_positions[i].basket_id == basket_id)
      {
         total += m_positions[i].profit;
         total += m_positions[i].commission;
         total += m_positions[i].swap;
      }
   }
   
   return total;
}

int CPositionManager::GetOpenPositionCount()
{
   int count = 0;
   for(int i = 0; i < m_position_count; i++)
   {
      if(m_positions[i].is_active)
         count++;
   }
   return count;
}

string CPositionManager::GetDiagnostics()
{
   int active = GetOpenPositionCount();
   return StringConcatenate("positions=", IntegerToString(m_position_count), " active=", IntegerToString(active));
}

#endif // POSITIONMANAGER_MQH_GUARD
