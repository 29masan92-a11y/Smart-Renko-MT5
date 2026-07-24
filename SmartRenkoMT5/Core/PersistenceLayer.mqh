//+------------------------------------------------------------------+
//| Persistence Layer - Concrete Implementation                      |
//+------------------------------------------------------------------+
#ifndef PERSISTENCELAYER_MQH_GUARD
#define PERSISTENCELAYER_MQH_GUARD

#include "Types.mqh"
#include "Interfaces.mqh"
#include <Files.mqh>

class CPersistenceLayer : public IPersistenceLayer
{
private:
   string                  m_prefix;
   bool                    m_initialized;
   string                  m_status;
   int                     m_file_handle;

   string                  GetBasketFileName(const string basket_id);
   string                  GetPositionsFileName(const string basket_id);
   string                  GetTrailingFileName(const string basket_id);
   string                  GetBalanceFileName(const string basket_id);
   string                  GetModeFileName();
   string                  GetProtectionFileName();
   string                  GetListFileName();

   bool                    WriteString(const string filename, const string data);
   bool                    ReadString(const string filename, string &data);
   bool                    DeleteFile(const string filename);
   bool                    FileExists(const string filename);

public:
   CPersistenceLayer();
   virtual ~CPersistenceLayer();
   
   virtual bool OnInit(const string prefix);
   virtual void OnDeinit();
   
   virtual bool SaveBasket(const SBasket &basket);
   virtual bool LoadBasket(string id, SBasket &basket);
   virtual bool DeleteBasket(const string id);
   virtual bool SavePositions(const SPosition &positions[], const int count);
   virtual bool LoadPositions(SPosition &positions[], int &count);
   virtual bool SaveTrailingState(const string basket_id, const double peak_profit, const bool activated);
   virtual bool LoadTrailingState(const string basket_id, double &peak_profit, bool &activated);
   virtual bool SaveBalanceSnapshot(const string basket_id, const double balance);
   virtual bool LoadBalanceSnapshot(const string basket_id, double &balance);
   virtual bool SaveModeState(const ENUM_TRADING_MODE mode);
   virtual bool LoadModeState(ENUM_TRADING_MODE &mode);
   virtual bool SavePendingProtection(const SRiskMetrics &metrics);
   virtual bool LoadPendingProtection(SRiskMetrics &metrics);
   virtual bool ClearAll();
   virtual bool ListBaskets(string &basket_ids[], int &count);
   virtual string GetStatus();
};

//+------------------------------------------------------------------+
//| CPersistenceLayer Implementation                                 |
//+------------------------------------------------------------------+
CPersistenceLayer::CPersistenceLayer() : m_prefix(""),
   m_initialized(false),
   m_status("not initialized"),
   m_file_handle(INVALID_HANDLE)
{
}

CPersistenceLayer::~CPersistenceLayer()
{
   OnDeinit();
}

string CPersistenceLayer::GetBasketFileName(const string basket_id)
{
   return StringConcatenate(m_prefix, "_basket_", basket_id, ".dat");
}

string CPersistenceLayer::GetPositionsFileName(const string basket_id)
{
   return StringConcatenate(m_prefix, "_positions_", basket_id, ".dat");
}

string CPersistenceLayer::GetTrailingFileName(const string basket_id)
{
   return StringConcatenate(m_prefix, "_trailing_", basket_id, ".dat");
}

string CPersistenceLayer::GetBalanceFileName(const string basket_id)
{
   return StringConcatenate(m_prefix, "_balance_", basket_id, ".dat");
}

string CPersistenceLayer::GetModeFileName()
{
   return StringConcatenate(m_prefix, "_mode.dat");
}

string CPersistenceLayer::GetProtectionFileName()
{
   return StringConcatenate(m_prefix, "_protection.dat");
}

string CPersistenceLayer::GetListFileName()
{
   return StringConcatenate(m_prefix, "_basket_list.dat");
}

bool CPersistenceLayer::OnInit(const string prefix)
{
   m_prefix = prefix;
   m_initialized = true;
   m_status = "initialized";
   return true;
}

void CPersistenceLayer::OnDeinit()
{
   m_initialized = false;
   m_status = "deinitialized";
}

bool CPersistenceLayer::FileExists(const string filename)
{
   m_file_handle = FileOpen(filename, FILE_READ|FILE_BIN|FILE_COMMON);
   if(m_file_handle == INVALID_HANDLE)
      return false;
   FileClose(m_file_handle);
   m_file_handle = INVALID_HANDLE;
   return true;
}

bool CPersistenceLayer::WriteString(const string filename, const string data)
{
   m_file_handle = FileOpen(filename, FILE_WRITE|FILE_BIN|FILE_COMMON);
   if(m_file_handle == INVALID_HANDLE)
   {
      m_status = StringConcatenate("write failed: ", filename);
      return false;
   }
   FileWriteString(m_file_handle, data);
   FileClose(m_file_handle);
   m_file_handle = INVALID_HANDLE;
   m_status = StringConcatenate("wrote: ", filename);
   return true;
}

bool CPersistenceLayer::ReadString(const string filename, string &data)
{
   m_file_handle = FileOpen(filename, FILE_READ|FILE_BIN|FILE_COMMON);
   if(m_file_handle == INVALID_HANDLE)
   {
      m_status = StringConcatenate("read failed: ", filename);
      return false;
   }
   data = FileReadString(m_file_handle);
   FileClose(m_file_handle);
   m_file_handle = INVALID_HANDLE;
   m_status = StringConcatenate("read: ", filename);
   return true;
}

bool CPersistenceLayer::DeleteFile(const string filename)
{
   bool result = FileDelete(filename, FILE_COMMON);
   m_status = StringConcatenate("delete ", filename, "=", (result ? "ok" : "fail"));
   return result;
}

bool CPersistenceLayer::SaveBasket(const SBasket &basket)
{
   if(!m_initialized)
      return false;
   
   string line = StringConcatenate(
      basket.id, "|",
      basket.symbol, "|",
      IntegerToString((int)basket.direction), "|",
      IntegerToString((int)basket.open_time), "|",
      DoubleToString(basket.start_balance), "|",
      (basket.is_active ? "1" : "0"), "|",
      IntegerToString(basket.add_entry_count), "|",
      DoubleToString(basket.peak_floating_profit), "|",
      (basket.trailing_activated ? "1" : "0"), "|",
      IntegerToString((int)basket.closure_reason), "|",
      IntegerToString((int)basket.state), "|",
      basket.persistence_version
   );
   
   bool result = WriteString(GetBasketFileName(basket.id), line);
   
   if(result)
   {
      string list[];
      int count = 0;
      if(ListBaskets(list, count))
      {
         bool found = false;
         for(int i = 0; i < count; i++)
         {
            if(list[i] == basket.id)
            {
               found = true;
               break;
            }
         }
         if(!found)
         {
            ArrayResize(list, count + 1);
            list[count] = basket.id;
            
            string list_data = "";
            for(int i = 0; i < count + 1; i++)
            {
               if(i > 0) list_data = StringConcatenate(list_data, "\n");
               list_data = StringConcatenate(list_data, list[i]);
            }
            WriteString(GetListFileName(), list_data);
         }
      }
   }
   
   return result;
}

bool CPersistenceLayer::LoadBasket(string id, SBasket &basket)
{
   if(!m_initialized)
      return false;
   
   string data;
   if(!ReadString(GetBasketFileName(id), data))
      return false;
   
   string parts[];
   StringSplit(data, '|', parts);
   
   if(ArraySize(parts) < 12)
   {
      m_status = "invalid basket data";
      return false;
   }
   
   ZeroMemory(basket);
   basket.id = parts[0];
   basket.symbol = parts[1];
   basket.direction = (ENUM_POSITION_TYPE)StringToInteger(parts[2]);
   basket.open_time = (datetime)StringToInteger(parts[3]);
   basket.start_balance = StringToDouble(parts[4]);
   basket.is_active = (parts[5] == "1");
   basket.add_entry_count = StringToInteger(parts[6]);
   basket.peak_floating_profit = StringToDouble(parts[7]);
   basket.trailing_activated = (parts[8] == "1");
   basket.closure_reason = (ENUM_CLOSURE_REASON)StringToInteger(parts[9]);
   basket.state = (ENUM_BASKET_STATE)StringToInteger(parts[10]);
   basket.persistence_version = parts[11];
   
   return true;
}

bool CPersistenceLayer::DeleteBasket(const string id)
{
   if(!m_initialized)
      return false;
   
   bool r1 = DeleteFile(GetBasketFileName(id));
   bool r2 = DeleteFile(GetPositionsFileName(id));
   bool r3 = DeleteFile(GetTrailingFileName(id));
   bool r4 = DeleteFile(GetBalanceFileName(id));
   
   string list_data;
   if(ReadString(GetListFileName(), list_data))
   {
      string lines[];
      StringSplit(list_data, '\n', lines);
      string new_list = "";
      bool first = true;
      for(int i = 0; i < ArraySize(lines); i++)
      {
         if(lines[i] == id) continue;
         if(!first) new_list = StringConcatenate(new_list, "\n");
         new_list = StringConcatenate(new_list, lines[i]);
         first = false;
      }
      WriteString(GetListFileName(), new_list);
   }
   
   return (r1 && r2 && r3 && r4);
}

bool CPersistenceLayer::SavePositions(const SPosition &positions[], const int count)
{
   if(!m_initialized || count <= 0)
      return false;
   
   string data = IntegerToString(count);
   for(int i = 0; i < count; i++)
   {
      data = StringConcatenate(data, "\n",
         IntegerToString((long)positions[i].position_ticket), "|",
         positions[i].symbol, "|",
         IntegerToString((int)positions[i].type), "|",
         DoubleToString(positions[i].volume), "|",
         DoubleToString(positions[i].open_price), "|",
         IntegerToString((int)positions[i].open_time), "|",
         DoubleToString(positions[i].profit), "|",
         DoubleToString(positions[i].commission), "|",
         DoubleToString(positions[i].swap), "|",
         IntegerToString(positions[i].magic_number), "|",
         positions[i].basket_id, "|",
         (positions[i].is_active ? "1" : "0"), "|",
         positions[i].comment
      );
   }
   
   return WriteString(GetPositionsFileName(positions[0].basket_id), data);
}

bool CPersistenceLayer::LoadPositions(SPosition &positions[], int &count)
{
   if(!m_initialized)
   {
      count = 0;
      return false;
   }
   
   string list_data;
   if(!ReadString(GetListFileName(), list_data))
   {
      count = 0;
      return false;
   }
   
   string basket_ids[];
   StringSplit(list_data, '\n', basket_ids);
   
   count = 0;
   ArrayFree(positions);
   
   for(int b = 0; b < ArraySize(basket_ids); b++)
   {
      if(basket_ids[b] == "") continue;
      
      string data;
      if(!ReadString(GetPositionsFileName(basket_ids[b]), data))
         continue;
      
      string lines[];
      StringSplit(data, '\n', lines);
      
      if(ArraySize(lines) < 1) continue;
      int pos_count = StringToInteger(lines[0]);
      
      for(int i = 1; i < ArraySize(lines) && count < pos_count + 1; i++)
      {
         if(lines[i] == "") continue;
         
         string parts[];
         StringSplit(lines[i], '|', parts);
         
         if(ArraySize(parts) < 13) continue;
         
         int new_size = count + 1;
         ArrayResize(positions, new_size);
         
         ZeroMemory(positions[count]);
         positions[count].position_ticket = StringToInteger(parts[0]);
         positions[count].symbol = parts[1];
         positions[count].type = (ENUM_POSITION_TYPE)StringToInteger(parts[2]);
         positions[count].volume = StringToDouble(parts[3]);
         positions[count].open_price = StringToDouble(parts[4]);
         positions[count].open_time = (datetime)StringToInteger(parts[5]);
         positions[count].profit = StringToDouble(parts[6]);
         positions[count].commission = StringToDouble(parts[7]);
         positions[count].swap = StringToDouble(parts[8]);
         positions[count].magic_number = StringToInteger(parts[9]);
         positions[count].basket_id = parts[10];
         positions[count].is_active = (parts[11] == "1");
         positions[count].comment = parts[12];
         count++;
      }
   }
   
   return true;
}

bool CPersistenceLayer::SaveTrailingState(const string basket_id, const double peak_profit, const bool activated)
{
   if(!m_initialized)
      return false;
   
   string data = StringConcatenate(DoubleToString(peak_profit), "|", (activated ? "1" : "0"));
   return WriteString(GetTrailingFileName(basket_id), data);
}

bool CPersistenceLayer::LoadTrailingState(const string basket_id, double &peak_profit, bool &activated)
{
   if(!m_initialized)
      return false;
   
   string data;
   if(!ReadString(GetTrailingFileName(basket_id), data))
   {
      peak_profit = 0.0;
      activated = false;
      return false;
   }
   
   string parts[];
   StringSplit(data, '|', parts);
   
   if(ArraySize(parts) < 2)
   {
      peak_profit = 0.0;
      activated = false;
      return false;
   }
   
   peak_profit = StringToDouble(parts[0]);
   activated = (parts[1] == "1");
   return true;
}

bool CPersistenceLayer::SaveBalanceSnapshot(const string basket_id, const double balance)
{
   if(!m_initialized)
      return false;
   
   string data = DoubleToString(balance);
   return WriteString(GetBalanceFileName(basket_id), data);
}

bool CPersistenceLayer::LoadBalanceSnapshot(const string basket_id, double &balance)
{
   if(!m_initialized)
      return false;
   
   string data;
   if(!ReadString(GetBalanceFileName(basket_id), data))
   {
      balance = 0.0;
      return false;
   }
   
   balance = StringToDouble(data);
   return true;
}

bool CPersistenceLayer::SaveModeState(const ENUM_TRADING_MODE mode)
{
   if(!m_initialized)
      return false;
   
   string data = IntegerToString((int)mode);
   return WriteString(GetModeFileName(), data);
}

bool CPersistenceLayer::LoadModeState(ENUM_TRADING_MODE &mode)
{
   if(!m_initialized)
      return false;
   
   string data;
   if(!ReadString(GetModeFileName(), data))
   {
      mode = TRADING_MODE_FULL_AUTO;
      return false;
   }
   
   mode = (ENUM_TRADING_MODE)StringToInteger(data);
   return true;
}

bool CPersistenceLayer::SavePendingProtection(const SRiskMetrics &metrics)
{
   if(!m_initialized)
      return false;
   
   string data = StringConcatenate(
      DoubleToString(metrics.daily_realized_loss), "|",
      DoubleToString(metrics.floating_drawdown), "|",
      DoubleToString(metrics.max_basket_loss), "|",
      IntegerToString(metrics.total_open_trades), "|",
      DoubleToString(metrics.symbol_exposure), "|",
      (metrics.emergency_flatten_active ? "1" : "0"), "|",
      (metrics.cooldown_active ? "1" : "0"), "|",
      IntegerToString((int)metrics.cooldown_until)
   );
   
   return WriteString(GetProtectionFileName(), data);
}

bool CPersistenceLayer::LoadPendingProtection(SRiskMetrics &metrics)
{
   if(!m_initialized)
      return false;
   
   string data;
   if(!ReadString(GetProtectionFileName(), data))
   {
      ZeroMemory(metrics);
      return false;
   }
   
   string parts[];
   StringSplit(data, '|', parts);
   
   if(ArraySize(parts) < 8)
   {
      ZeroMemory(metrics);
      return false;
   }
   
   ZeroMemory(metrics);
   metrics.daily_realized_loss = StringToDouble(parts[0]);
   metrics.floating_drawdown = StringToDouble(parts[1]);
   metrics.max_basket_loss = StringToDouble(parts[2]);
   metrics.total_open_trades = StringToInteger(parts[3]);
   metrics.symbol_exposure = StringToDouble(parts[4]);
   metrics.emergency_flatten_active = (parts[5] == "1");
   metrics.cooldown_active = (parts[6] == "1");
   metrics.cooldown_until = (datetime)StringToInteger(parts[7]);
   
   return true;
}

bool CPersistenceLayer::ClearAll()
{
   if(!m_initialized)
      return false;
   
   string list_data;
   if(ReadString(GetListFileName(), list_data))
   {
      string basket_ids[];
      StringSplit(list_data, '\n', basket_ids);
      
      for(int i = 0; i < ArraySize(basket_ids); i++)
      {
         if(basket_ids[i] == "") continue;
         DeleteFile(GetBasketFileName(basket_ids[i]));
         DeleteFile(GetPositionsFileName(basket_ids[i]));
         DeleteFile(GetTrailingFileName(basket_ids[i]));
         DeleteFile(GetBalanceFileName(basket_ids[i]));
      }
   }
   
   DeleteFile(GetListFileName());
   DeleteFile(GetModeFileName());
   DeleteFile(GetProtectionFileName());
   
   m_status = "cleared all";
   return true;
}

bool CPersistenceLayer::ListBaskets(string &basket_ids[], int &count)
{
   if(!m_initialized)
   {
      count = 0;
      ArrayFree(basket_ids);
      return false;
   }
   
   string data;
   if(!ReadString(GetListFileName(), data))
   {
      count = 0;
      ArrayFree(basket_ids);
      return false;
   }
   
   string raw[];
   StringSplit(data, '\n', raw);
   
   count = 0;
   ArrayFree(basket_ids);
   
   for(int i = 0; i < ArraySize(raw); i++)
   {
      if(raw[i] != "")
      {
         int new_size = count + 1;
         ArrayResize(basket_ids, new_size);
         basket_ids[count] = raw[i];
         count++;
      }
   }
   
   return true;
}

string CPersistenceLayer::GetStatus()
{
   return m_status;
}

#endif // PERSISTENCELAYER_MQH_GUARD
