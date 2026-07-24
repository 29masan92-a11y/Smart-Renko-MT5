#property strict
#property indicator_chart_window
input int Days=100;// Days Boxs
input bool OpenCloseBox=true;// Open Close Boxs
datetime T;
string MQL_name;
int f,Bar;

//| Custom indicator initialization function                         |

int OnInit()
  {
   MQL_name=MQLInfoString(MQL_PROGRAM_NAME);

   return(INIT_SUCCEEDED);
  }

//| Expert deinitialization function                                 |

void OnDeinit(const int reason)
  {
//---
   ObjectsDeleteAll(0,MQL_name);
//---
  }

//| Custom indicator iteration function                              |

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(iTime(NULL,PERIOD_D1,0)!=T)
     {
      T=iTime(NULL,PERIOD_D1,0);
      DrawWeekBox();
     }
//---
   return(rates_total);
  }

void DrawWeekBox()
  {
   if(f==0){Bar=Days;}else{Bar=1;}
   for(int iw=0;iw<Bar;iw++)
     {
      string tname=TimeToString(iTime(NULL,PERIOD_D1,iw));
      datetime t=iTime(NULL,PERIOD_D1,iw);
      double high=iHigh(NULL,PERIOD_D1,iw);
      double low=iLow(NULL,PERIOD_D1,iw);
      double open=iOpen(NULL,PERIOD_D1,iw);
      double close=iClose(NULL,PERIOD_D1,iw);
      color clr=clrGreen;string TXT="Monday";
      if(TimeDayOfWeek(iTime(NULL,PERIOD_D1,iw))==2){clr=clrTeal;TXT="Tuesday";}
      if(TimeDayOfWeek(iTime(NULL,PERIOD_D1,iw))==3){clr=clrTeal;TXT="Wednesday";}
      if(TimeDayOfWeek(iTime(NULL,PERIOD_D1,iw))==4){clr=clrTeal;TXT="Thursday";}
      if(TimeDayOfWeek(iTime(NULL,PERIOD_D1,iw))==5){clr=clrRed;TXT="Friday";}
      Draw_TrandLine_or_Box(0,"WeekDay"+tname,OBJ_RECTANGLE,t+86400,high,t,low,clr,+1,STYLE_SOLID);
      DrawTXT(TXT+tname,TXT,t,high,clr);
      if(OpenCloseBox==true)
        {
         if(open>close){clr=clrRed;}else{clr=clrBlue;}
         Draw_TrandLine_or_Box(0,"WeekDayBS"+tname,OBJ_RECTANGLE,t+86400,open,t,close,clr,1,STYLE_DOT);
        }
     }
  }

void DrawTXT(string name,string text,datetime time,double price,color clr,ENUM_ANCHOR_POINT ANCHOR_=ANCHOR_LEFT_LOWER,int size=10)
  {
   name=MQL_name+name;
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(0,name,OBJ_TEXT,0,time,price);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
   else
     {
      ObjectMove(0,name,0,time,price);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
     }
  }

void Draw_TrandLine_or_Box(int sub_window,string name,ENUM_OBJECT OBJ_,datetime t1,double p1,datetime t2,double p2,color clr,int scale,int STYLE,bool BACK=false)
  {
   name=MQL_name+name;
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(0,name,OBJ_,sub_window,t1,p1,t2,p2);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,0);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BACK,BACK);
      ObjectSetInteger(0,name,OBJPROP_RAY,true);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,scale);
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE);
     }
   else
     {
      ObjectMove(0,name,0,t1,p1);
      ObjectMove(0,name,1,t2,p2);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,scale);
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE);
      ObjectSetInteger(0,name,OBJPROP_BACK,BACK);
     }
  }