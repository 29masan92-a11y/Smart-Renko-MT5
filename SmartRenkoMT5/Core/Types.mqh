//+------------------------------------------------------------------+
//| Trading Mode Enum                                                 |
//+------------------------------------------------------------------+
#ifndef TYPES_MQH_GUARD
#define TYPES_MQH_GUARD

enum ENUM_TRADING_MODE
{
   TRADING_MODE_MANUAL = 0,
   TRADING_MODE_SEMI_AUTO = 1,
   TRADING_MODE_FULL_AUTO = 2
};

//+------------------------------------------------------------------+
//| Basket State Enum                                                 |
//+------------------------------------------------------------------+
enum ENUM_BASKET_STATE
{
   BASKET_STATE_IDLE = 0,
   BASKET_STATE_PENDING_FIRST_ENTRY = 1,
   BASKET_STATE_ACTIVE = 2,
   BASKET_STATE_TRAILING_ACTIVE = 3,
   BASKET_STATE_CLOSING = 4,
   BASKET_STATE_CLOSED = 5,
   BASKET_STATE_RECOVERY_REBUILD = 6
};

//+------------------------------------------------------------------+
//| Closure Reason Enum                                               |
//+------------------------------------------------------------------+
enum ENUM_CLOSURE_REASON
{
   CLOSURE_REASON_NONE = 0,
   CLOSURE_REASON_MANUAL_CLOSE = 1,
   CLOSURE_REASON_TRAILING_STOP = 2,
   CLOSURE_REASON_RISK_LIMIT = 3,
   CLOSURE_REASON_EMERGENCY_FLATTEN = 4,
   CLOSURE_REASON_SESSION_END = 5,
   CLOSURE_REASON_RECOVERY = 6
};

//+------------------------------------------------------------------+
//| Signal Direction Enum                                             |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_DIRECTION
{
   SIGNAL_DIRECTION_NONE = 0,
   SIGNAL_DIRECTION_BUY = 1,
   SIGNAL_DIRECTION_SELL = 2
};

//+------------------------------------------------------------------+
//| Signal Source Enum                                                |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_SOURCE
{
   SIGNAL_SOURCE_ENTRY_STRATEGY = 0,
   SIGNAL_SOURCE_EXIT_STRATEGY = 1,
   SIGNAL_SOURCE_RISK_MANAGER = 2,
   SIGNAL_SOURCE_MANUAL_OVERRIDE = 3
};

//+------------------------------------------------------------------+
//| Position Type Enum                                                |
//+------------------------------------------------------------------+
enum ENUM_POSITION_TYPE
{
   POSITION_TYPE_LONG = 0,
   POSITION_TYPE_SHORT = 1
};

//+------------------------------------------------------------------+
//| Broker Order Type Enum                                            |
//+------------------------------------------------------------------+
enum ENUM_BROKER_ORDER_TYPE
{
   BROKER_ORDER_TYPE_BUY = 0,
   BROKER_ORDER_TYPE_SELL = 1,
   BROKER_ORDER_TYPE_CLOSE_BUY = 2,
   BROKER_ORDER_TYPE_CLOSE_SELL = 3,
   BROKER_ORDER_TYPE_CLOSE_ALL = 4
};

//+------------------------------------------------------------------+
//| Execution Result Struct                                           |
//+------------------------------------------------------------------+
struct SExecutionResult
{
   bool        success;
   ulong       ticket;
   string      error_message;
   datetime    execution_time;
   double      executed_volume;
   double      executed_price;
};

//+------------------------------------------------------------------+
//| Signal Struct                                                     |
//+------------------------------------------------------------------+
struct SSignal
{
   ENUM_SIGNAL_DIRECTION  direction;
   double                 strength;
   ENUM_SIGNAL_SOURCE     source;
   long                   brick_index;
   datetime               signal_time;
   string                 metadata;
};

//+------------------------------------------------------------------+
//| Position Struct (internal representation)                         |
//+------------------------------------------------------------------+
struct SPosition
{
   ulong       position_ticket;
   string      symbol;
   ENUM_POSITION_TYPE type;
   double      volume;
   double      open_price;
   datetime    open_time;
   double      profit;
   double      commission;
   double      swap;
   long        magic_number;
   string      basket_id;
   bool        is_active;
   string      comment;
};

//+------------------------------------------------------------------+
//| Basket Struct                                                     |
//+------------------------------------------------------------------+
struct SBasket
{
   string                  id;
   string                  symbol;
   ENUM_POSITION_TYPE      direction;
   datetime                open_time;
   double                  start_balance;
   bool                    is_active;
   int                     add_entry_count;
   double                  peak_floating_profit;
   bool                    trailing_activated;
   ENUM_CLOSURE_REASON     closure_reason;
   ENUM_BASKET_STATE       state;
   string                  persistence_version;
};

//+------------------------------------------------------------------+
//| Renko Brick Struct                                                |
//+------------------------------------------------------------------+
struct SRenkoBrick
{
   double      price;
   datetime    time;
   bool        is_bullish;
   int         brick_index;
   double      brick_size;
};

//+------------------------------------------------------------------+
//| Risk Metrics Struct                                               |
//+------------------------------------------------------------------+
struct SRiskMetrics
{
   double      daily_realized_loss;
   double      floating_drawdown;
   double      max_basket_loss;
   int         total_open_trades;
   double      symbol_exposure;
   bool        emergency_flatten_active;
   bool        cooldown_active;
   datetime    cooldown_until;
};

//+------------------------------------------------------------------+
//| Money Management Input Struct                                     |
//+------------------------------------------------------------------+
struct SMoneyInput
{
   double      balance;
   double      equity;
   double      free_margin;
   double      stop_loss_pips;
   ENUM_TRADING_MODE trading_mode;
   double      basket_risk_percent;
   bool        is_add_on;
   int         add_entry_number;
};

//+------------------------------------------------------------------+
//| Money Management Result Struct                                    |
//+------------------------------------------------------------------+
struct SMoneyResult
{
   double      suggested_lot;
   bool        allowed;
   string      rejection_reason;
};

//+------------------------------------------------------------------+
//| Basket Metrics Struct (for reporting/GUI)                         |
//+------------------------------------------------------------------+
struct SBasketMetrics
{
   string      basket_id;
   ENUM_BASKET_STATE state;
   double      floating_profit;
   double      start_balance;
   double      peak_profit;
   bool        trailing_active;
   int         open_positions;
   datetime    open_time;
   ENUM_CLOSURE_REASON closure_reason;
};

//+------------------------------------------------------------------+
//| Preset Profile Struct                                             |
//+------------------------------------------------------------------+
struct SPresetProfile
{
   string      name;
   string      instrument;
   string      trading_style;
   string      version;
   string      description;
   bool        is_prop_challenge;
};

#endif // TYPES_MQH_GUARD
