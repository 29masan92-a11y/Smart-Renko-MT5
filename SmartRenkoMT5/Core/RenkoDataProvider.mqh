//+------------------------------------------------------------------+
//| Renko Data Provider - Concrete Implementation                    |
//+------------------------------------------------------------------+
#ifndef RENKODATAPROVIDER_MQH_GUARD
#define RENKODATAPROVIDER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CRenkoDataProvider : public IRenkoDataProvider
{
private:
   string                  m_symbol;
   double                  m_brick_size;
   SRenkoBrick             m_current_brick;
   SRenkoBrick             m_brick_history[];
   int                     m_history_count;
   int                     m_brick_index;
   datetime                m_last_tick_time;
   bool                    m_initialized;
   string                  m_status;
   bool                    m_is_bullish;
   double                  m_last_close_price;

   bool                   GetMidPrice(double &price);
   bool                   AddBrick(const double price, const bool is_bullish);
   void                   UpdateCurrentBrick(const double price, const bool is_bullish);

public:
   CRenkoDataProvider();
   virtual ~CRenkoDataProvider();
   
   virtual bool OnInit(const string symbol, const double brick_size);
   virtual void OnDeinit();
   virtual bool OnTick();
   
   virtual bool GetCurrentBrick(SRenkoBrick &brick);
   virtual ENUM_SIGNAL_DIRECTION GetDirection();
   virtual bool IsContinuation();
   virtual bool IsReversal();
   virtual double GetBrickSize();
   virtual bool GetHistoricalContext(const int count, SRenkoBrick &bricks[]);
   virtual bool IsFresh(const datetime max_age_seconds = 60);
   virtual int GetBrickIndex();
   virtual void SetBrickSize(const double size);
   virtual string GetStatus();
};

//+------------------------------------------------------------------+
//| CRenkoDataProvider Implementation                               |
//+------------------------------------------------------------------+
CRenkoDataProvider::CRenkoDataProvider() : m_symbol(""),
   m_brick_size(0.0),
   m_history_count(0),
   m_brick_index(0),
   m_last_tick_time(0),
   m_initialized(false),
   m_status("not initialized"),
   m_is_bullish(true),
   m_last_close_price(0.0)
{
   ZeroMemory(m_current_brick);
   ArrayFree(m_brick_history);
}

CRenkoDataProvider::~CRenkoDataProvider()
{
   OnDeinit();
}

bool CRenkoDataProvider::GetMidPrice(double &price)
{
   double bid = 0.0;
   double ask = 0.0;
   
   if(!SymbolInfoDouble(m_symbol, SYMBOL_BID, bid))
      return false;
   if(!SymbolInfoDouble(m_symbol, SYMBOL_ASK, ask))
      return false;
   
   price = (bid + ask) / 2.0;
   return true;
}

bool CRenkoDataProvider::AddBrick(const double price, const bool is_bullish)
{
   m_last_close_price = price;
   m_is_bullish = is_bullish;
   
   SRenkoBrick new_brick;
   ZeroMemory(new_brick);
   new_brick.price = price;
   new_brick.time = TimeCurrent();
   new_brick.is_bullish = is_bullish;
   new_brick.brick_index = m_brick_index;
   new_brick.brick_size = m_brick_size;
   
   int new_size = m_history_count + 1;
   ArrayResize(m_brick_history, new_size);
   m_brick_history[m_history_count] = new_brick;
   m_history_count++;
   
   m_current_brick = new_brick;
   m_brick_index++;
   m_last_tick_time = TimeCurrent();
   
   if(new_size > 200)
   {
      int shift = new_size - 200;
      for(int i = 0; i < m_history_count - 1; i++)
         m_brick_history[i] = m_brick_history[i + shift];
      m_history_count = 200;
      ArrayResize(m_brick_history, m_history_count);
      m_brick_index -= shift;
   }
   
   return true;
}

void CRenkoDataProvider::UpdateCurrentBrick(const double price, const bool is_bullish)
{
   m_current_brick.price = price;
   m_current_brick.time = TimeCurrent();
   m_current_brick.is_bullish = is_bullish;
   m_last_close_price = price;
   m_is_bullish = is_bullish;
   m_last_tick_time = TimeCurrent();
}

bool CRenkoDataProvider::OnInit(const string symbol, const double brick_size)
{
   if(brick_size <= 0.0)
      return false;
   
   m_symbol = symbol;
   m_brick_size = brick_size;
   m_history_count = 0;
   m_brick_index = 0;
   m_last_tick_time = TimeCurrent();
   m_initialized = true;
   m_status = "initialized";
   m_is_bullish = true;
   m_last_close_price = 0.0;
   ArrayFree(m_brick_history);
   ZeroMemory(m_current_brick);
   
   double price = 0.0;
   if(GetMidPrice(price))
   {
      AddBrick(price, true);
   }
   
   return true;
}

void CRenkoDataProvider::OnDeinit()
{
   m_initialized = false;
   m_status = "deinitialized";
   ArrayFree(m_brick_history);
   m_history_count = 0;
}

bool CRenkoDataProvider::OnTick()
{
   if(!m_initialized)
      return false;
   
   double price = 0.0;
   if(!GetMidPrice(price))
      return false;
   
   if(m_last_close_price == 0.0)
   {
      AddBrick(price, true);
      return true;
   }
   
   if(m_is_bullish)
   {
      if(price >= m_last_close_price + m_brick_size)
      {
         AddBrick(price, true);
      }
      else if(price <= m_last_close_price - 2.0 * m_brick_size)
      {
         AddBrick(price, false);
      }
      else
      {
         UpdateCurrentBrick(price, true);
      }
   }
   else
   {
      if(price <= m_last_close_price - m_brick_size)
      {
         AddBrick(price, false);
      }
      else if(price >= m_last_close_price + 2.0 * m_brick_size)
      {
         AddBrick(price, true);
      }
      else
      {
         UpdateCurrentBrick(price, false);
      }
   }
   
   return true;
}

bool CRenkoDataProvider::GetCurrentBrick(SRenkoBrick &brick)
{
   if(!m_initialized || m_history_count <= 0)
      return false;
   
   brick = m_current_brick;
   return true;
}

ENUM_SIGNAL_DIRECTION CRenkoDataProvider::GetDirection()
{
   if(!m_initialized || m_history_count <= 0)
      return SIGNAL_DIRECTION_NONE;
   
   return m_is_bullish ? SIGNAL_DIRECTION_BUY : SIGNAL_DIRECTION_SELL;
}

bool CRenkoDataProvider::IsContinuation()
{
   if(!m_initialized || m_history_count < 2)
      return false;
   
   SRenkoBrick prev = m_brick_history[m_history_count - 2];
   return (prev.is_bullish == m_current_brick.is_bullish);
}

bool CRenkoDataProvider::IsReversal()
{
   if(!m_initialized || m_history_count < 2)
      return false;
   
   SRenkoBrick prev = m_brick_history[m_history_count - 2];
   return (prev.is_bullish != m_current_brick.is_bullish);
}

double CRenkoDataProvider::GetBrickSize()
{
   return m_brick_size;
}

bool CRenkoDataProvider::GetHistoricalContext(const int count, SRenkoBrick &bricks[])
{
   ArrayFree(bricks);
   
   if(!m_initialized || m_history_count <= 0)
      return false;
   
   int actual_count = MathMin(count, m_history_count);
   ArrayResize(bricks, actual_count);
   
   for(int i = 0; i < actual_count; i++)
   {
      int src_idx = m_history_count - actual_count + i;
      bricks[i] = m_brick_history[src_idx];
   }
   
   return true;
}

bool CRenkoDataProvider::IsFresh(const datetime max_age_seconds)
{
   if(!m_initialized || m_history_count <= 0)
      return false;
   
   datetime now = TimeCurrent();
   return ((now - m_last_tick_time) <= max_age_seconds);
}

int CRenkoDataProvider::GetBrickIndex()
{
   return m_brick_index;
}

void CRenkoDataProvider::SetBrickSize(const double size)
{
   if(size > 0.0)
      m_brick_size = size;
}

string CRenkoDataProvider::GetStatus()
{
   return StringConcatenate("symbol=", m_symbol, " brick_size=", DoubleToString(m_brick_size), " bricks=", IntegerToString(m_history_count), " direction=", EnumToString(GetDirection()), " status=", m_status);
}

#endif // RENKODATAPROVIDER_MQH_GUARD
