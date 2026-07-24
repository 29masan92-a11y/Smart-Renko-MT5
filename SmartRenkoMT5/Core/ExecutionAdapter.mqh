//+------------------------------------------------------------------+
//| Execution Adapter - Concrete Placeholder                         |
//+------------------------------------------------------------------+
#ifndef EXECUTIONADAPTER_MQH_GUARD
#define EXECUTIONADAPTER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"

class CExecutionAdapter : public IExecutionAdapter
{
private:
   string                  m_symbol;
   long                    m_magic_number;
   bool                    m_initialized;
   string                  m_last_error;

public:
   CExecutionAdapter();
   virtual ~CExecutionAdapter();
   
   virtual bool OnInit(const string symbol, const long magic_number);
   virtual void OnDeinit();
   
   virtual SExecutionResult SendOrder(const ENUM_BROKER_ORDER_TYPE type, const double volume, const double price, const double sl, const double tp, const string comment);
   virtual bool ClosePosition(const ulong ticket);
   virtual bool CloseAllPositions();
   virtual bool ModifyPosition(const ulong ticket, const double sl, const double tp);
   virtual bool GetOpenPositions(SPosition &positions[], const string symbol = "", const long magic = -1);
   virtual bool GetAccountInfo(double &balance, double &equity, double &free_margin, double &margin);
   virtual bool GetSymbolInfo(const string symbol, double &lot_step, double &min_lot, double &max_lot, double &point, int &digits);
   virtual bool IsConnected();
   virtual string GetLastError();
};

//+------------------------------------------------------------------+
//| CExecutionAdapter Implementation                                 |
//+------------------------------------------------------------------+
CExecutionAdapter::CExecutionAdapter() : m_symbol(""),
   m_magic_number(0),
   m_initialized(false),
   m_last_error("not initialized")
{
}

CExecutionAdapter::~CExecutionAdapter()
{
   OnDeinit();
}

bool CExecutionAdapter::OnInit(const string symbol, const long magic_number)
{
   m_symbol = symbol;
   m_magic_number = magic_number;
   m_initialized = true;
   m_last_error = "";
   return true;
}

void CExecutionAdapter::OnDeinit()
{
   m_initialized = false;
   m_last_error = "deinitialized";
}

SExecutionResult CExecutionAdapter::SendOrder(const ENUM_BROKER_ORDER_TYPE type, const double volume, const double price, const double sl, const double tp, const string comment)
{
   SExecutionResult result;
   ZeroMemory(result);
   result.success = false;
   result.error_message = "execution adapter: stub implementation";
   return result;
}

bool CExecutionAdapter::ClosePosition(const ulong ticket)
{
   m_last_error = "stub: ClosePosition not implemented";
   return false;
}

bool CExecutionAdapter::CloseAllPositions()
{
   m_last_error = "stub: CloseAllPositions not implemented";
   return false;
}

bool CExecutionAdapter::ModifyPosition(const ulong ticket, const double sl, const double tp)
{
   m_last_error = "stub: ModifyPosition not implemented";
   return false;
}

bool CExecutionAdapter::GetOpenPositions(SPosition &positions[], const string symbol, const long magic)
{
   ArrayFree(positions);
   m_last_error = "stub: GetOpenPositions not implemented";
   return false;
}

bool CExecutionAdapter::GetAccountInfo(double &balance, double &equity, double &free_margin, double &margin)
{
   m_last_error = "stub: GetAccountInfo not implemented";
   return false;
}

bool CExecutionAdapter::GetSymbolInfo(const string symbol, double &lot_step, double &min_lot, double &max_lot, double &point, int &digits)
{
   m_last_error = "stub: GetSymbolInfo not implemented";
   return false;
}

bool CExecutionAdapter::IsConnected()
{
   return false;
}

string CExecutionAdapter::GetLastError()
{
   return m_last_error;
}

#endif // EXECUTIONADAPTER_MQH_GUARD
