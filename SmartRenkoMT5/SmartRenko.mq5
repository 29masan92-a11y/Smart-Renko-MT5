//+------------------------------------------------------------------+
//| Smart Renko for MT5 - EA Entry Point                             |
//+------------------------------------------------------------------+
#property copyright "Smart Renko MT5"
#property version   "1.00"
#property strict

#include "Core/CoreModules.mqh"
#include "Core/BasketManager.mqh"
#include "Core/PositionManager.mqh"
#include "Core/SignalManager.mqh"
#include "Core/RiskManager.mqh"
#include "Core/MoneyManager.mqh"
#include "Core/TrailingManager.mqh"
#include "Core/ExecutionAdapter.mqh"
#include "Core/PersistenceLayer.mqh"
#include "Core/NotificationManager.mqh"
#include "Core/ReportingEngine.mqh"
#include "Core/GuiLayer.mqh"
#include "Core/PresetProfileManager.mqh"
#include "Core/VpsRunner.mqh"
#include "Core/RenkoDataProvider.mqh"
#include "Core/EntryStrategies.mqh"
#include "Core/ExitStrategies.mqh"

//--- Global handles
CCoreOrchestrator*     g_orchestrator = NULL;
CRenkoDataProvider*    g_renko_provider = NULL;
CRenkoContinuationEntryStrategy* g_continuation_strategy = NULL;
CRenkoReversalEntryStrategy*     g_reversal_strategy = NULL;
CBasketTrailingExitStrategy*     g_trailing_exit_strategy = NULL;
CIndividualPositionExitStrategy* g_position_exit_strategy = NULL;
CBasketManager*        g_basket_mgr = NULL;
CPositionManager*      g_position_mgr = NULL;
CSignalManager*        g_signal_mgr = NULL;
CRiskManager*          g_risk_mgr = NULL;
CMoneyManager*         g_money_mgr = NULL;
CTrailingManager*      g_trailing_mgr = NULL;
CExecutionAdapter*     g_execution = NULL;
CPersistenceLayer*     g_persistence = NULL;
CGuiLayer*             g_gui = NULL;
CVpsRunner*            g_vps = NULL;
CNotificationManager*  g_notifier = NULL;
CReportingEngine*      g_reporter = NULL;
CPresetProfileManager* g_presets = NULL;

//--- Configuration
input ENUM_TRADING_MODE  InpTradingMode        = TRADING_MODE_FULL_AUTO;
input string             InpSymbol             = "";
input long               InpMagicNumber        = 123456;
input bool               InpEnableGui          = true;
input bool               InpEnableVps          = false;
input bool               InpEnableNotifications = true;
input bool               InpEnableReporting    = true;
input string             InpProfileName        = "Default";
input double             InpRenkoBrickSize     = 0.0;
input string             InpRiskConfig         = "daily_realized_loss_limit=100;floating_drawdown_threshold=50;max_total_open_trades=10;spread_max=50;cooldown_minutes=30";
input string             InpMoneyConfig        = "use_balance_based=1;balance_factor=1;fixed_lot=0.1";
input string             InpTrailingConfig     = "include_commission=1;include_swap=1;min_eval_seconds=1;drops_to_close=2";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   string symbol = InpSymbol;
   if(symbol == "" || symbol == "0")
      symbol = _Symbol;

   g_orchestrator = new CCoreOrchestrator();
   if(g_orchestrator == NULL)
   {
      Print("FATAL: Failed to allocate CoreOrchestrator");
      return(INIT_FAILED);
   }

   bool init_ok = g_orchestrator.Init(symbol, InpMagicNumber, InpTradingMode);
   if(!init_ok)
   {
      Print("FATAL: CoreOrchestrator initialization failed");
      delete g_orchestrator;
      g_orchestrator = NULL;
      return(INIT_FAILED);
   }

   g_renko_provider = new CRenkoDataProvider();
   if(g_renko_provider != NULL)
   {
      double brick_size = InpRenkoBrickSize;
      if(brick_size <= 0.0)
      {
         double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
         int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         brick_size = 10.0 * point * MathPow(10.0, digits - 3);
         if(brick_size <= 0.0)
            brick_size = 0.01;
      }
      g_renko_provider.OnInit(symbol, brick_size);
      g_orchestrator.SetRenkoProvider(g_renko_provider);
   }

   if(InpEnableGui)
   {
      g_gui = new CGuiLayer();
      if(g_gui != NULL)
      {
         g_gui.OnInit(ChartID(), 0);
         g_orchestrator.SetGuiLayer(g_gui);
      }
   }

   if(InpEnableNotifications)
   {
      g_notifier = new CNotificationManager();
      if(g_notifier != NULL)
      {
         g_notifier.OnInit(true, true, true);
         g_orchestrator.SetNotificationManager(g_notifier);
      }
   }

   if(InpEnableReporting)
   {
      g_reporter = new CReportingEngine();
      if(g_reporter != NULL)
      {
         string report_path = "Reports";
         g_reporter.OnInit(report_path);
         g_orchestrator.SetReportingEngine(g_reporter);
      }
   }

   if(InpEnableVps)
   {
      g_vps = new CVpsRunner();
      if(g_vps != NULL)
      {
         g_vps.OnInit(symbol, InpMagicNumber);
         g_orchestrator.SetVpsRunner(g_vps);
         g_vps.Start();
      }
   }

   g_presets = new CPresetProfileManager();
   if(g_presets != NULL)
   {
      g_presets.OnInit("Profiles");
      g_orchestrator.SetPresetManager(g_presets);
   }

   g_persistence = new CPersistenceLayer();
   if(g_persistence != NULL)
   {
      g_persistence.OnInit("SmartRenko");
      g_orchestrator.SetPersistenceLayer(g_persistence);
   }

   g_execution = new CExecutionAdapter();
   if(g_execution != NULL)
   {
      g_execution.OnInit(symbol, InpMagicNumber);
      g_orchestrator.SetExecutionAdapter(g_execution);
   }

   g_basket_mgr = new CBasketManager();
   if(g_basket_mgr != NULL)
   {
      g_basket_mgr.OnInit(symbol, InpMagicNumber, g_persistence);
      g_orchestrator.SetBasketManager(g_basket_mgr);
   }

   g_position_mgr = new CPositionManager();
   if(g_position_mgr != NULL)
   {
      g_position_mgr.OnInit(symbol, InpMagicNumber, g_execution);
      g_orchestrator.SetPositionManager(g_position_mgr);
   }

   g_signal_mgr = new CSignalManager();
   if(g_signal_mgr != NULL)
   {
      g_signal_mgr.OnInit(InpMagicNumber);
      g_orchestrator.SetSignalManager(g_signal_mgr);
   }

   g_risk_mgr = new CRiskManager();
   if(g_risk_mgr != NULL)
   {
      SRiskMetrics metrics;
      ZeroMemory(metrics);
      g_risk_mgr.OnInit(metrics, InpRiskConfig);
      g_orchestrator.SetRiskManager(g_risk_mgr);
   }

   g_money_mgr = new CMoneyManager();
   if(g_money_mgr != NULL)
   {
      g_money_mgr.OnInit(InpMoneyConfig);
      g_orchestrator.SetMoneyManager(g_money_mgr);
   }

    g_trailing_mgr = new CTrailingManager();
    if(g_trailing_mgr != NULL)
    {
       g_trailing_mgr.OnInit("", 0.0, 0.0, 0.0, InpTrailingConfig);
       g_trailing_mgr.SetPersistenceLayer(g_persistence);
       g_orchestrator.SetTrailingManager(g_trailing_mgr);
    }

    g_continuation_strategy = new CRenkoContinuationEntryStrategy();
    if(g_continuation_strategy != NULL)
    {
       g_continuation_strategy.OnInit(symbol, InpMagicNumber);
       g_continuation_strategy.SetRenkoProvider(g_renko_provider);
       g_continuation_strategy.LoadParameters("min_continuation_bricks=2;lookback_bricks=10;min_strength=0.5;require_no_reversal=1");
    }

    g_reversal_strategy = new CRenkoReversalEntryStrategy();
    if(g_reversal_strategy != NULL)
    {
       g_reversal_strategy.OnInit(symbol, InpMagicNumber);
       g_reversal_strategy.SetRenkoProvider(g_renko_provider);
       g_reversal_strategy.LoadParameters("min_reversal_bricks=1;min_strength=0.7");
    }

    g_trailing_exit_strategy = new CBasketTrailingExitStrategy();
    if(g_trailing_exit_strategy != NULL)
    {
       g_trailing_exit_strategy.OnInit(symbol, InpMagicNumber);
       g_trailing_exit_strategy.SetTrailingManager(g_trailing_mgr);
    }

    g_position_exit_strategy = new CIndividualPositionExitStrategy();
    if(g_position_exit_strategy != NULL)
    {
       g_position_exit_strategy.OnInit(symbol, InpMagicNumber);
       g_position_exit_strategy.LoadParameters("fixed_profit_threshold=0.0;fixed_loss_threshold=0.0");
    }

    if(g_signal_mgr != NULL)
    {
       if(g_continuation_strategy != NULL)
          g_signal_mgr.RegisterEntryStrategy(g_continuation_strategy);
       if(g_reversal_strategy != NULL)
          g_signal_mgr.RegisterEntryStrategy(g_reversal_strategy);
       if(g_trailing_exit_strategy != NULL)
          g_signal_mgr.RegisterExitStrategy(g_trailing_exit_strategy);
       if(g_position_exit_strategy != NULL)
          g_signal_mgr.RegisterExitStrategy(g_position_exit_strategy);
       if(g_renko_provider != NULL)
          g_signal_mgr.SetRenkoProvider(g_renko_provider);
    }

    if(g_basket_mgr != NULL)
    {
       if(!g_basket_mgr.ReconstructFromPersistence())
       {
          if(!g_basket_mgr.ReconstructFromPositions())
          {
             Print("INFO: No active basket to reconstruct");
          }
       }
    }

   EventSetTimer(1);

   Print("Smart Renko MT5 initialized. Symbol=", symbol, " Magic=", InpMagicNumber, " Mode=", EnumToString(InpTradingMode));
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

    if(g_renko_provider != NULL)
    {
       g_renko_provider.OnDeinit();
       delete g_renko_provider;
       g_renko_provider = NULL;
    }

    if(g_continuation_strategy != NULL)
    {
       g_continuation_strategy.OnDeinit();
       delete g_continuation_strategy;
       g_continuation_strategy = NULL;
    }

    if(g_reversal_strategy != NULL)
    {
       g_reversal_strategy.OnDeinit();
       delete g_reversal_strategy;
       g_reversal_strategy = NULL;
    }

    if(g_trailing_exit_strategy != NULL)
    {
       g_trailing_exit_strategy.OnDeinit();
       delete g_trailing_exit_strategy;
       g_trailing_exit_strategy = NULL;
    }

    if(g_position_exit_strategy != NULL)
    {
       g_position_exit_strategy.OnDeinit();
       delete g_position_exit_strategy;
       g_position_exit_strategy = NULL;
    }

    if(g_vps != NULL)
   {
      g_vps.Stop();
      g_vps.OnDeinit();
      delete g_vps;
      g_vps = NULL;
   }

   if(g_gui != NULL)
   {
      g_gui.OnDeinit();
      delete g_gui;
      g_gui = NULL;
   }

   if(g_notifier != NULL)
   {
      g_notifier.OnDeinit();
      delete g_notifier;
      g_notifier = NULL;
   }

   if(g_reporter != NULL)
   {
      g_reporter.OnDeinit();
      delete g_reporter;
      g_reporter = NULL;
   }

   if(g_trailing_mgr != NULL)
   {
      g_trailing_mgr.OnDeinit();
      delete g_trailing_mgr;
      g_trailing_mgr = NULL;
   }

   if(g_money_mgr != NULL)
   {
      g_money_mgr.OnDeinit();
      delete g_money_mgr;
      g_money_mgr = NULL;
   }

   if(g_risk_mgr != NULL)
   {
      g_risk_mgr.OnDeinit();
      delete g_risk_mgr;
      g_risk_mgr = NULL;
   }

   if(g_signal_mgr != NULL)
   {
      g_signal_mgr.OnDeinit();
      delete g_signal_mgr;
      g_signal_mgr = NULL;
   }

   if(g_position_mgr != NULL)
   {
      g_position_mgr.OnDeinit();
      delete g_position_mgr;
      g_position_mgr = NULL;
   }

   if(g_basket_mgr != NULL)
   {
      g_basket_mgr.OnDeinit();
      delete g_basket_mgr;
      g_basket_mgr = NULL;
   }

   if(g_execution != NULL)
   {
      g_execution.OnDeinit();
      delete g_execution;
      g_execution = NULL;
   }

   if(g_persistence != NULL)
   {
      g_persistence.OnDeinit();
      delete g_persistence;
      g_persistence = NULL;
   }

   if(g_presets != NULL)
   {
      g_presets.OnDeinit();
      delete g_presets;
      g_presets = NULL;
   }

   if(g_orchestrator != NULL)
   {
      g_orchestrator.Deinit();
      delete g_orchestrator;
      g_orchestrator = NULL;
   }

   if(g_reporter != NULL)
   {
      g_reporter.OnDeinit();
      delete g_reporter;
      g_reporter = NULL;
   }

   if(g_notifier != NULL)
   {
      g_notifier.OnDeinit();
      delete g_notifier;
      g_notifier = NULL;
   }

   if(g_gui != NULL)
   {
      g_gui.OnDeinit();
      delete g_gui;
      g_gui = NULL;
   }

   if(g_vps != NULL)
   {
      g_vps.Stop();
      g_vps.OnDeinit();
      delete g_vps;
      g_vps = NULL;
   }

   Print("Smart Renko MT5 deinitialized. Reason=", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(g_orchestrator == NULL || !g_orchestrator.IsInitialized())
      return;

   if(g_renko_provider != NULL)
      g_renko_provider.OnTick();

   g_orchestrator.OnTick();

   if(g_gui != NULL && g_gui.IsVisible())
      g_gui.Refresh();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(g_orchestrator == NULL || !g_orchestrator.IsInitialized())
      return;

   g_orchestrator.OnTimer();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_KEYDOWN)
   {
      int key = (int)lparam;
      if(key == 66)
      {
         if(g_orchestrator != NULL && g_orchestrator.IsInitialized())
            g_orchestrator.RequestManualEntry(POSITION_TYPE_LONG);
      }
      else if(key == 83)
      {
         if(g_orchestrator != NULL && g_orchestrator.IsInitialized())
            g_orchestrator.RequestManualEntry(POSITION_TYPE_SHORT);
      }
   }
    
   if(g_gui != NULL)
      g_gui.OnChartEvent(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| TesterInit / TesterDeinit / TesterTrade (optional for tester)    |
//+------------------------------------------------------------------+
double OnTester()
{
   return 0.0;
}

void OnTesterInit()
{
}

void OnTesterDeinit()
{
}

void OnTesterTrade()
{
}
