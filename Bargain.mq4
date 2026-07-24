#property indicator_chart_window
#property strict

#define        G_PREFIX            "xr3"
#define        MFONT               "Tahoma"
#define        _LF                 "\n"


extern int		TimeFrame			= PERIOD_D1;
extern int		AdrPeriod			= 21;
extern double 	EcnComm				= 0.0;
extern int		Rows				   = 24;
extern bool 	Sort				   = true;


int				SymbolCount = 0;
datetime 		TimeStart;
string 			Symbols[];
double 			SymRQ[][5], DisRQ[][5];


int 			OnInit() {

	int			Offset 				= 116;
	int			hFile 				= FileOpenHistory("symbols.sel", FILE_BIN|FILE_READ);
	string      _read;

	int sc = (int(FileSize(hFile)) - 4) / 128;
   ArrayResize(Symbols, sc);

	FileSeek(hFile, 4, SEEK_SET);

	for(int i = 0; i < sc; i++) {
	   _read = FileReadString(hFile, 12);
		Symbols[SymbolCount] = _read;
		SymbolCount++;
		FileSeek(hFile, Offset, SEEK_CUR);
	}

	FileClose(hFile);
	ArrayResize(SymRQ, SymbolCount);
	ArrayResize(DisRQ, SymbolCount);
	TimeStart = TimeCurrent();
	EventSetMillisecondTimer(50);

	ClearDisplay();
	return INIT_SUCCEEDED;
}


void  		OnDeinit(const int Reason) {

	ClearDisplay();
}


void 			OnTimer() {

	double 		askprice, bidprice, spread, ticksize, tickvalue, cpips, rq;
	int			c = 0, i, j, k = 0, l = 0, per;
	datetime	runtime;
	string 		_sym;

	static long  counter = 1;

	for(i = 0; i < SymbolCount; i++) {
		_sym = Symbols[i];
		per = MathMin(AdrPeriod, iBars(_sym, TimeFrame) - 1);
		ticksize = MarketInfo(_sym, MODE_TICKSIZE);
		tickvalue = MarketInfo(_sym, MODE_TICKVALUE);
		cpips = Divide(ticksize * (EcnComm /  100000.0) * MarketInfo(_sym, MODE_MARGINREQUIRED) * AccountLeverage(), tickvalue);
		if(StringFind(_sym, "XAU") != -1) cpips /= 2.0;
		if(StringFind(_sym, "XAG") != -1) cpips /= 4.0;
		askprice = MarketInfo(_sym, MODE_ASK);
		bidprice = MarketInfo(_sym, MODE_BID);
		spread = askprice - bidprice;
		if(spread == 0.0)
		   {
		      if(MarketInfo(_sym, MODE_DIGITS) == 5) {
		         spread = 0.000005;
		      }   
		      
		      if(MarketInfo(_sym, MODE_DIGITS) == 3) {
		         spread = 0.0005;
		      }
            
            if(MarketInfo(_sym, MODE_DIGITS) == 2) {
		         spread = 0.005;
		      }
		      
		      if(MarketInfo(_sym, MODE_DIGITS) == 1) {
		         spread = 0.05;
		      }
		      
		      if(MarketInfo(_sym, MODE_DIGITS) == 0) {
		         spread = 0.5;
		      }
		   }

		rq = Divide(iATR(_sym, TimeFrame, per , 0), spread);

		if(askprice != 0 && bidprice != 0) {
			SymRQ[c, 2] = i;
			SymRQ[c, 1] += rq;
			SymRQ[c, 0] = SymRQ[c, 1] / counter;
			c++;
		}
	}

	runtime = TimeCurrent() - TimeStart;
	ArrayCopy(DisRQ, SymRQ);
	if(Sort) ArraySort(DisRQ, c, 0, MODE_DESCEND);
	
	rLabel("CrimL", TerminalCompany(), 8, MFONT, Magenta, 10, 10, 0, 0, ANCHOR_LEFT_UPPER);
	rLabel("TimeL", DoubleToStr(runtime / (1440 * 60), 0) + "d " + TimeToStr(runtime, TIME_SECONDS), 8, MFONT, OrangeRed, 10, 10, 0, 1, ANCHOR_RIGHT_UPPER);
	rLabel("TickL", "Bargain Index", 8, MFONT, DodgerBlue, 200, 10, 0, 0, ANCHOR_LEFT_UPPER);
	
	for(i = 0; i < c; i++) {
		j 	= int(DisRQ[i, 2]);
		rq	= DisRQ[i, 0];
		rLabel("SymL" + string(i), StringSubstr(Symbols[j], 0, StringFind(Symbols[j], ".lmx")), 8, MFONT, White,  10 + k * 150,  40 + l * 12, 0, 0, ANCHOR_LEFT_UPPER);
		rLabel("SymV" + string(i), DoubleToStr(rq, 2), 8, MFONT, Lime,  100 + k * 150,  40 + l * 12, 0, 0, ANCHOR_LEFT_UPPER);
		l++;
		if(MathMod(i + 1, Rows) == 0) {k++; l = 0;}
	}

	counter++;	
}


int      OnCalculate                (const int        rates_total,
                                     const int        prev_calculated,
                                     const datetime   &time[],
                                     const double     &open[],
                                     const double     &high[],
                                     const double     &low[],
                                     const double     &close[],
                                     const long       &tick_volume[],
                                     const long       &volume[],
                                     const int        &spread[]) {
                                     
   return rates_total;
}


double   Divide                     (double n, double d) {

   // A quick and dirty bypass to avoid division by zero.                                                                                                |

	if(d == 0.0) return 0.0;
	return n / d;
}


void 		rLabel					      (string _Name, string _oText, int fSize, string _fType, color fColor, int xDist, int yDist, int Window, int Corner, int Anchor = ANCHOR_RIGHT_UPPER) {

	if (StringFind(_Name, "_bkg" + G_PREFIX) != 0) _Name = StringConcatenate(G_PREFIX, _Name);

	if (ObjectFind(_Name) < 0) {
		ObjectCreate(_Name, OBJ_LABEL, Window, 0, 0);
		ObjectSet(_Name, OBJPROP_CORNER, Corner);
		ObjectSet(_Name, OBJPROP_SELECTABLE, false);
		ObjectSetString(ChartID(), _Name, OBJPROP_TOOLTIP, _LF);
		ObjectSetInteger(ChartID(), _Name, OBJPROP_ANCHOR, Anchor);
	}
	ObjectSet(_Name, OBJPROP_XDISTANCE, xDist);
   ObjectSet(_Name, OBJPROP_YDISTANCE, yDist);
	ObjectSetText(_Name, _oText, fSize, _fType, fColor);
}


void     ClearPrefixed              (string prefix) {

   // Deletes all objects with a given prefix.                                                                                                           |

	for (int i = ObjectsTotal() -1; i >= 0; i--) {
		if (StringFind(ObjectName(i), prefix) == 0) ObjectDelete(ObjectName(i));
	}
}


void 		ClearDisplay       		   () {

	ClearPrefixed(G_PREFIX);
	ClearPrefixed("_bkg" + G_PREFIX);
}
