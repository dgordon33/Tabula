int focusedChannel() {
  return lx.engine.focusedChannel.getValuei();
}

class UILoopRecorder extends UIWindow {
  
  private final UILabel slotLabel;
  private final String[] labels = new String[] { "-", "-", "-", "-" };
  
  UILoopRecorder(UI ui) {
    super(ui, "LOOP RECORDER", Tabula.this.width-144, Tabula.this.height - 126, 140, 122);
    float yPos = TITLE_LABEL_HEIGHT;
    
    final UIButton playButton = new UIButton(6, yPos, 40, 20);
    playButton
    .setLabel("PLAY")
    .addToContainer(this);
      
    final UIButton stopButton = new UIButton(6 + (this.width-8)/3, yPos, 40, 20);
    stopButton
    .setMomentary(true)
    .setLabel("STOP")
    .addToContainer(this);
      
    final UIButton armButton = new UIButton(6 + 2*(this.width-8)/3, yPos, 40, 20);
    armButton
    .setLabel("ARM")
    .setActiveColor(0xcc3333)
    .addToContainer(this);
    
    yPos += 24;
    final UIButton loopButton = new UIButton(4, yPos, this.width-8, 20);
    loopButton
    .setInactiveLabel("One-shot")
    .setActiveLabel("Looping")
    .addToContainer(this);
    
    yPos += 24;
    slotLabel = new UILabel(4, yPos, this.width-8, 20);
    slotLabel
    .setLabel("-")
    .setAlignment(CENTER, CENTER)
    .setBackgroundColor(#333333)
    .setBorderColor(#666666)
    .addToContainer(this); 
    
    yPos += 24;
    new UIButton(4, yPos, (this.width-12)/2, 20) {
      protected void onToggle(boolean active) {
        if (active) {
          String fileName = labels[automationSlot.getValuei()].equals("-") ? "set.json" : labels[automationSlot.getValuei()]; 
          selectOutput("Save Set",  "saveSet", new File(dataPath(fileName)), UILoopRecorder.this);
        }
      }
    }
    .setMomentary(true)
    .setLabel("Save")
    .addToContainer(this);
    
    new UIButton(this.width - (this.width-12)/2 - 4, yPos, (this.width-12)/2, 20) {
      protected void onToggle(boolean active) {
        if (active) {
          selectInput("Load Set",  "loadSet", new File(dataPath("")), UILoopRecorder.this);
        }
      }
    }
    .setMomentary(true)
    .setLabel("Load")
    .addToContainer(this);
    
    final LXParameterListener listener;
    automationSlot.addListener(listener = new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        LXAutomationRecorder auto = automation[automationSlot.getValuei()];
        stopButton.setParameter(automationStop[automationSlot.getValuei()]);
        playButton.setParameter(auto.isRunning);
        armButton.setParameter(auto.armRecord);
        loopButton.setParameter(auto.looping);
        slotLabel.setLabel(labels[automationSlot.getValuei()]);
      }
    });
    listener.onParameterChanged(null);

    // slotLabel.setLabel(labels[automationSlot.getValuei()] = "Burning Man Playlist.json");
  }

  public void saveSet(File file) {
    if (file != null) {
      saveBytes(file.getPath(), automation[automationSlot.getValuei()].toJson().toString().getBytes());
      slotLabel.setLabel(labels[automationSlot.getValuei()] = file.getName());
    }
  }
  
  public void loadSet(File file) {
    if (file != null) {
      String jsonStr = new String(loadBytes(file.getPath()));
      JsonArray jsonArr = new Gson().fromJson(jsonStr, JsonArray.class);
      automation[automationSlot.getValuei()].loadJson(jsonArr);
      slotLabel.setLabel(labels[automationSlot.getValuei()] = file.getName());
    }
  }

}

class UIChannelFaders extends UI2dContext {
  
  final static int SPACER = 30;
  final static int MASTER = 0;
  final static int PADDING = 4;
  final static int BUTTON_HEIGHT = 14;
  final static int FADER_WIDTH = 40;
  final static int WIDTH = 2 * SPACER + PADDING + MASTER + (PADDING+FADER_WIDTH)*(Engine.NUM_CHANNELS+2);
  final static int HEIGHT = 140;
  final static int PERF_PADDING = PADDING + 1;
  
  UIChannelFaders(final UI ui) {
    super(ui, Tabula.this.width/2-WIDTH/2, Tabula.this.height-HEIGHT-PADDING, WIDTH, HEIGHT);
    setBackgroundColor(#292929);
    setBorderColor(#444444);
    int di = 0;
    final UISlider[] sliders = new UISlider[Engine.NUM_CHANNELS];
    final UIButton[] cues = new UIButton[Engine.NUM_CHANNELS];
    final UILabel[] labels = new UILabel[Engine.NUM_CHANNELS];
    for (int i = 0; i < Engine.NUM_CHANNELS; i++) {
      final LXChannel channel = lx.engine.getChannel(i);
      float xPos = PADDING + channel.getIndex()*(PADDING+FADER_WIDTH) + SPACER;
      
      previewChannels[channel.getIndex()] = new BooleanParameter("PRV");
      
      previewChannels[channel.getIndex()].addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          cues[channel.getIndex()].setActive(previewChannels[channel.getIndex()].isOn());
        }
      });
      
      cues[channel.getIndex()] = new UIButton(xPos, PADDING, FADER_WIDTH, BUTTON_HEIGHT) {
        void onToggle(boolean active) {
          previewChannels[channel.getIndex()].setValue(active);
        }
      };
      cues[channel.getIndex()]
      .setActive(previewChannels[channel.getIndex()].isOn())
      .addToContainer(this);
      
      sliders[channel.getIndex()] = new UISlider(UISlider.Direction.VERTICAL, xPos, 1*BUTTON_HEIGHT + 2*PADDING, FADER_WIDTH, this.height - 3*BUTTON_HEIGHT - 5*PADDING) {
        protected void onMousePressed(MouseEvent mouseEvent, float mx, float my) {
          super.onMousePressed(mouseEvent, mx, my);
          lx.engine.focusedChannel.setValue(channel.getIndex());
        }
        protected void onKeyPressed(KeyEvent keyEvent, char keyChar, int keyCode) {
          super.onKeyPressed(keyEvent, keyChar, keyCode);
          if ((keyChar == ' ') || (keyCode == java.awt.event.KeyEvent.VK_ENTER)) {
            lx.engine.focusedChannel.setValue(channel.getIndex());
          }
        }
        @Override
        protected void onDraw(UI ui, PGraphics pg) {
          int primaryColor = ui.theme.getPrimaryColor();
          ui.theme.setPrimaryColor(0xff222222);
          super.onDraw(ui, pg);
          ui.theme.setPrimaryColor(primaryColor);
        }
      };
      sliders[channel.getIndex()]
      .setParameter(channel.getFader())
      .setShowLabel(false)
      .addToContainer(this);
            
      labels[channel.getIndex()] = new UILabel(xPos, this.height - 2*PADDING - 2*BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT);
      labels[channel.getIndex()]
      .setLabel(shortPatternName(channel.getActivePattern()))
      .setAlignment(CENTER, CENTER)
      .setFontColor(#999999)
      .setBackgroundColor(#292929)
      .setBorderColor(#666666)
      .addToContainer(this);

      LXChannel.AbstractListener changeTextListener = new LXChannel.AbstractListener() {

        void patternWillChange(LXChannel channel, LXPattern pattern, LXPattern nextPattern) {
          labels[channel.getIndex()].setLabel(shortPatternName(nextPattern));
          labels[channel.getIndex()].setFontColor(#292929);
          labels[channel.getIndex()].setBackgroundColor(#666699);
        }
        
        void patternDidChange(LXChannel channel, LXPattern pattern) {
          labels[channel.getIndex()].setLabel(shortPatternName(pattern));
          labels[channel.getIndex()].setFontColor(#999999);
          labels[channel.getIndex()].setBackgroundColor(#292929);
        }
      };
      
      channel.addListener(changeTextListener);

      changeTextListener.patternDidChange(channel, channel.getNextPattern());
    }
    
    float xPos = this.width - 2 * (FADER_WIDTH + PADDING) - SPACER;
    UISlider masterSlider = new UISlider(UISlider.Direction.VERTICAL, xPos, PADDING, FADER_WIDTH, this.height-3*PADDING-1*BUTTON_HEIGHT) {
      @Override
      protected void onDraw(UI ui, PGraphics pg) {
        int primaryColor = ui.theme.getPrimaryColor();
        ui.theme.setPrimaryColor(0xff222222);
        super.onDraw(ui, pg);
        ui.theme.setPrimaryColor(primaryColor);
      }
    };
    masterSlider
    .setShowLabel(false)
    .addToContainer(this);

    masterSlider.setParameter(outputBrightness);
    
    LXParameterListener listener;
    lx.engine.focusedChannel.addListener(listener = new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        for (int i = 0; i < sliders.length; ++i) {
          sliders[i].setBackgroundColor((i == focusedChannel()) ? ui.theme.getFocusColor() : #333333);
        }
      }
    });
    listener.onParameterChanged(lx.engine.focusedChannel);
    
    float labelX = PADDING;
    
    new UILabel(labelX, PADDING+2, 0, 0)
    .setLabel("CUE")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(labelX, 2*PADDING+1*BUTTON_HEIGHT+2, 0, 0)
    .setLabel("LEVEL")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(labelX, this.height - 2*PADDING - 2*BUTTON_HEIGHT + 3, 0, 0)
    .setLabel("PTN")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(labelX, this.height - PADDING - BUTTON_HEIGHT + 3, 0, 0)
    .setLabel("CPU")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - 2 * (PADDING + FADER_WIDTH) - SPACER, this.height-PADDING-BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("MASTER")
    .setAlignment(CENTER, CENTER)
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UIPerfMeters()
    .setPosition(SPACER+PADDING, PADDING)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING, PADDING, BUTTON_HEIGHT - 1)
    .setLabel("CHAN")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("COPY")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 2 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("FX")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 3 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("INPUT")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 4 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("MIDI")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 5 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("OUT")
    .setFontColor(#666666)
    .addToContainer(this);
    
    new UILabel(this.width - SPACER, 2 + PADDING + 6 * (PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH, BUTTON_HEIGHT)
    .setLabel("TOTAL")
    .setFontColor(#666666)
    .addToContainer(this);
    
  }
  
  private String shortPatternName(LXPattern pattern) {
    String simpleName = pattern.getClass().getSimpleName(); 
    return simpleName.substring(0, Math.min(7, simpleName.length()));
  }
  
  class UIPerfMeters extends UI2dComponent {
    
    DampedParameter dampers[] = new DampedParameter[Engine.NUM_CHANNELS+7];
    BasicParameter perfs[] = new BasicParameter[Engine.NUM_CHANNELS+7];
   
    UIPerfMeters() {
      for (int i = 0; i < Engine.NUM_CHANNELS+7; ++i) {
        lx.addModulator((dampers[i] = new DampedParameter(perfs[i] = new BasicParameter("PERF", 0), 3))).start();
      }
    } 
    
    public void onDraw(UI ui, PGraphics pg) {
      for (int i = 0; i < Engine.NUM_CHANNELS; i++) {
        LXChannel channel = lx.engine.getChannel(i);
        LXPattern pattern = channel.getActivePattern();
        float goMillis = pattern.timer.runNanos / 1000000.;
        float fps60 = 1000 / 60. / 3. / 5;
        perfs[channel.getIndex()].setValue(Utils.constrain((goMillis-1) / fps60, 0, 1));
      }

      float engMillis = lx.engine.timer.channelNanos / 1000000.;
      perfs[Engine.NUM_CHANNELS].setValue(Utils.constrain(engMillis / (1000. / 60. / 5), 0, 1));
      
      engMillis = lx.engine.timer.copyNanos / 1000000.;
      perfs[Engine.NUM_CHANNELS+1].setValue(Utils.constrain(engMillis / (1000. / 60. / 5), 0, 1));
      
      engMillis = lx.engine.timer.fxNanos / 1000000.;
      perfs[Engine.NUM_CHANNELS+2].setValue(Utils.constrain(engMillis / (1000. / 60. / 5), 0, 1));
      
      engMillis = lx.engine.timer.inputNanos / 1000000.;
      perfs[Engine.NUM_CHANNELS+3].setValue(Utils.constrain(engMillis / (1000. / 60. / 5), 0, 1));
      
      engMillis = lx.engine.timer.midiNanos / 1000000.;
      perfs[Engine.NUM_CHANNELS+4].setValue(Utils.constrain(engMillis / (1000. / 60. / 5), 0, 1));
      
      engMillis = lx.engine.timer.outputNanos / 1000000.;
      perfs[Engine.NUM_CHANNELS+5].setValue(Utils.constrain(engMillis / (1000. / 60. / 5), 0, 1));

      engMillis = lx.engine.timer.runNanos / 1000000.;
      perfs[Engine.NUM_CHANNELS+6].setValue(Utils.constrain(engMillis / (1000. / 60. / 5), 0, 1));
      
      for (int i = 0; i < Engine.NUM_CHANNELS; ++i) {
        float val = dampers[i].getValuef();
        pg.stroke(#666666);
        pg.fill(#292929);
        pg.rect(i*(PADDING + FADER_WIDTH), HEIGHT - 2 * PADDING - BUTTON_HEIGHT, FADER_WIDTH-1, BUTTON_HEIGHT-1); 
        pg.fill(lx.hsb(120*(1-val), 50, 80));
        pg.noStroke();
        pg.rect(i*(PADDING + FADER_WIDTH)+1, HEIGHT - 2 * PADDING - BUTTON_HEIGHT + 1, val * (FADER_WIDTH-2), BUTTON_HEIGHT-2);
      }

      for (int i = Engine.NUM_CHANNELS; i < Engine.NUM_CHANNELS + 7; ++i) {
        float val = dampers[i].getValuef();
        pg.stroke(#666666);
        pg.fill(#292929);
        pg.rect((Engine.NUM_CHANNELS + 1)*(PADDING + FADER_WIDTH), (i - (Engine.NUM_CHANNELS))*(PERF_PADDING + BUTTON_HEIGHT-1), FADER_WIDTH-1, BUTTON_HEIGHT-1); 
        pg.fill(lx.hsb(120*(1-val), 50, 80));
        pg.noStroke();
        pg.rect((Engine.NUM_CHANNELS + 1)*(PADDING + FADER_WIDTH) + 1, (i - (Engine.NUM_CHANNELS))*(PERF_PADDING + BUTTON_HEIGHT-1)+1, val * (FADER_WIDTH-2), BUTTON_HEIGHT-2);
      }

      redraw();
    }
  }
}

class UIMultiDeck extends UIWindow implements InterfaceController {

  private final static int KNOBS_PER_ROW = 4;

  static final int NUM_PATTERNS_VISIBLE = 10;
  static final int PATTERN_ROW_HEIGHT = 20;
  static final int PATTERN_LIST_HEIGHT = NUM_PATTERNS_VISIBLE * PATTERN_ROW_HEIGHT;
  
  public final static int DEFAULT_WIDTH = 140;
  public final static int DEFAULT_HEIGHT = 158 + PATTERN_LIST_HEIGHT;

  final UIItemList[] patternLists;
  final UIToggleSet[] blendModes;
  final LXChannel.Listener[] lxListeners;
  final UIKnob[] knobs;

  public UIMultiDeck(UI ui) {
    super(ui, "CHANNEL " + (focusedChannel()+1), Tabula.this.width - 4 - DEFAULT_WIDTH, Tabula.this.height - 128 - DEFAULT_HEIGHT, DEFAULT_WIDTH, DEFAULT_HEIGHT);
    int yp = TITLE_LABEL_HEIGHT;

    patternLists = new UIItemList[Engine.NUM_CHANNELS];
    blendModes = new UIToggleSet[Engine.NUM_CHANNELS];
    lxListeners = new LXChannel.Listener[patternLists.length];
    for (int i = 0; i < Engine.NUM_CHANNELS; i++) {
      LXChannel channel = lx.engine.getChannel(i);
      List<UIItemList.Item> items = new ArrayList<UIItemList.Item>();
      for (LXPattern p : channel.getPatterns()) {
        items.add(new PatternScrollItem(channel, p));
      }
      patternLists[channel.getIndex()] = new UIItemList(1, yp, this.width - 2, PATTERN_LIST_HEIGHT).setItems(items);
      patternLists[channel.getIndex()].setVisible(channel.getIndex() == focusedChannel());
      patternLists[channel.getIndex()].addToContainer(this);      
    }
    
    yp += patternLists[0].getHeight() + 10;
    knobs = new UIKnob[Engine.NUM_KNOBS];
    for (int ki = 0; ki < knobs.length; ++ki) {
      knobs[ki] = new UIKnob(5 + 34 * (ki % KNOBS_PER_ROW), yp
        + (ki / KNOBS_PER_ROW) * 48);
      knobs[ki].addToContainer(this);
    }
    
    yp += 100;
    for (int i = 0; i < Engine.NUM_CHANNELS; i++) {
      LXChannel channel = lx.engine.getChannel(i);
      blendModes[channel.getIndex()] = new UIToggleSet(4, yp, this.width-8, 18)
      .setOptions(new String[] { "ADD", "MLT", "LITE", "SUBT" })
      .setParameter(getFaderTransition(channel).blendMode)
      .setEvenSpacing();
      blendModes[channel.getIndex()].setVisible(channel.getIndex() == focusedChannel());
      blendModes[channel.getIndex()].addToContainer(this);
    }
     
    for (int i = 0; i < Engine.NUM_CHANNELS; i++) {
      LXChannel channel = lx.engine.getChannel(i); 
      lxListeners[channel.getIndex()] = new LXChannel.AbstractListener() {
        @Override
        public void patternWillChange(LXChannel channel, LXPattern pattern,
            LXPattern nextPattern) {
          patternLists[channel.getIndex()].redraw();
        }

        @Override
        public void patternDidChange(LXChannel channel, LXPattern pattern) {
          List<LXPattern> patterns = channel.getPatterns();
          for (int i = 0; i < patterns.size(); ++i) {
            if (patterns.get(i) == pattern) {
              patternLists[channel.getIndex()].setFocusIndex(i);
              break;
            }
          }  
          
          patternLists[channel.getIndex()].redraw();
          if (channel.getIndex() == focusedChannel()) {
            int pi = 0;
            for (LXParameter parameter : pattern.getParameters()) {
              if (pi >= knobs.length) {
                break;
              }
              if (parameter instanceof LXListenableNormalizedParameter) {
                knobs[pi++].setParameter((LXListenableNormalizedParameter)parameter);
              }
            }
            while (pi < knobs.length) {
              knobs[pi++].setParameter(null);
            }
          }
        }
      };
      channel.addListener(lxListeners[channel.getIndex()]);
      lxListeners[channel.getIndex()].patternDidChange(channel, channel.getActivePattern());
    }
    
    lx.engine.focusedChannel.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        LXChannel channel = lx.engine.getChannel(focusedChannel()); 
        
        setTitle("CHANNEL " + (channel.getIndex() + 1));
        redraw();
        
        lxListeners[channel.getIndex()].patternDidChange(channel, channel.getActivePattern());
        
        int pi = 0;
        for (UIItemList patternList : patternLists) {
          patternList.setVisible(pi == focusedChannel());
          ++pi;
        }
        pi = 0;
        for (UIToggleSet blendMode : blendModes) {
          blendMode.setVisible(pi == focusedChannel());
          ++pi;
        }
      }
    });
    
  }
  
  void select() {
    patternLists[focusedChannel()].select();
  }
  
  float amt = 0;
  void knob(int delta) {
    if (delta > 64) {
      delta = delta - 128;
    }
    amt += delta / 4.;
    if (amt > 1) {
      scroll(1);
      amt -= 1;
    } else if (amt < -1) {
      scroll(-1);
      amt += 1;
    }
  }
  
  void selectPattern(int channel, int index) {
    lx.engine.getChannel(channel).goIndex(patternLists[channel].getScrollOffset() + index);
  }
  
  void pagePatterns(int channel) {
    int offset = patternLists[channel].getScrollOffset();
    patternLists[channel].setScrollOffset(offset + 5);
    if (patternLists[channel].getScrollOffset() == offset) {
      patternLists[channel].setScrollOffset(0);
    }
  }
  
  void scroll(int delta) {
    UIItemList list = patternLists[focusedChannel()]; 
    list.setFocusIndex(list.getFocusIndex() + delta);
  } 

  private class PatternScrollItem extends UIItemList.AbstractItem {

    private final LXChannel channel;
    private final LXPattern pattern;

    private final String label;

    PatternScrollItem(LXChannel channel, LXPattern pattern) {
      this.channel = channel;
      this.pattern = pattern;
      this.label = UI.uiClassName(pattern, "Pattern");
    }

    public String getLabel() {
      return this.label;
    }

    public boolean isSelected() {
      return this.channel.getActivePattern() == this.pattern;
    }

    public boolean isPending() {
      return this.channel.getNextPattern() == this.pattern;
    }

    public void onMousePressed() {
      this.channel.goPattern(this.pattern);
    }
  }
}

class UIEffects extends UIWindow {
  
  final int KNOBS_PER_ROW = 4;
  
  UIEffects(UI ui, LXListenableNormalizedParameter[] effectKnobParameters) {
    super(ui, "MASTER EFFECTS", Tabula.this.width-144, 110, 140, 120);
    
    int yp = TITLE_LABEL_HEIGHT;
    for (int ki = 0; ki < 8; ++ki) {
      new UIKnob(5 + 34 * (ki % KNOBS_PER_ROW), yp + (ki / KNOBS_PER_ROW) * 48)
      .setParameter(effectKnobParameters[ki])
      .addToContainer(this);
    }
    yp += 98;
    
  } 
  
}

class UIMasterBpm extends UIWindow {
  
  final static int BUTT_WIDTH = 12 * 3;
  final static int BUTT_HEIGHT = 20;
  final static int SPACING = 4;
  final static int MARGIN = 2 * SPACING;
  
  final private BPMTool bpmTool;
  
  UIMasterBpm(UI ui, float x, float y, final BPMTool bpmTool) {
    super(ui, "MASTER BPM", x, y, 140, 102);
    int yPos = TITLE_LABEL_HEIGHT - 3;
    int xPos = MARGIN;
    int windowWidth = 140;
    int windowHeight = 102;
    this.bpmTool = bpmTool;

    new UIKnob(xPos, yPos)
    .setParameter(bpmTool.modulationController.tempoAdapter.bpm)
    .addToContainer(this);
    
    xPos += BUTT_WIDTH + SPACING;
    
    new UIButton(xPos, yPos, BUTT_WIDTH + 1, BUTT_HEIGHT)
    .setLabel("TAP")
    .setMomentary(true)
    .setParameter(bpmTool.tapTempo)
    .addToContainer(this);
    
    xPos += BUTT_WIDTH + 1 + SPACING;
    
    new UIButton(xPos, yPos, BUTT_WIDTH / 2 + 2, BUTT_HEIGHT)
    .setLabel("-")
    .setMomentary(true)
    .setParameter(bpmTool.nudgeDownTempo)
    .addToContainer(this);
    
    xPos += BUTT_WIDTH / 2 + 2 + SPACING;
    
    new UIButton(xPos, yPos, BUTT_WIDTH / 2 + 2, BUTT_HEIGHT)
    .setLabel("+")
    .setMomentary(true)
    .setParameter(bpmTool.nudgeUpTempo)
    .addToContainer(this);
    
    xPos = MARGIN + BUTT_WIDTH + SPACING;
    yPos += BUTT_HEIGHT + SPACING;

    new UIToggleSet(xPos, yPos, windowWidth - xPos - MARGIN, BUTT_HEIGHT)
    .setOptions(bpmTool.beatLabels)
    .setParameter(bpmTool.beatType)
    .addToContainer(this);
    
    yPos += BUTT_HEIGHT + SPACING;

    xPos = MARGIN;

    new UIToggleSet(xPos, yPos, windowWidth - xPos - MARGIN, BUTT_HEIGHT)
    .setOptions(bpmTool.bpmLabels)
    .setParameter(bpmTool.tempoLfoType)
    .addToContainer(this);
    
    new UIBeatIndicator(windowWidth * 2 / 3, MARGIN, bpmTool.modulationController.tempoAdapter)
    .addToContainer(this);
  }
}

class UIBeatIndicator extends UI2dComponent implements LXParameterListener {
  
  final private TempoAdapter tempoAdapter;
  private boolean lightOn;
  
  protected UIBeatIndicator(float x, float y, TempoAdapter tempoAdapter) {
    super(x, y, 6, 6);
    this.tempoAdapter = tempoAdapter;
    lightOn = shouldLightBeOn();
    
    tempoAdapter.ramp.addListener(this);
  }
  
  protected void onDraw(UI ui, PGraphics pg) {
    if (shouldLightBeOn()) {
      pg.fill(0xFFFF0000);
    } else {
      pg.fill(getBackgroundColor());
    }
    pg.ellipse(getWidth() / 2, getHeight() / 2, getWidth(), getHeight());
  }
  
  public void onParameterChanged(LXParameter parameter) {
    if (shouldLightBeOn() != lightOn) {
      redraw();
      lightOn = shouldLightBeOn();
    }
  }
  
  private boolean shouldLightBeOn() {
    return tempoAdapter.tempo.ramp() < 0.1;
  }
}

