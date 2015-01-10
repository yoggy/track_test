import cc.arduino.*;
import processing.serial.*;
import controlP5.*;

Arduino arduino;
ControlP5 cp5;
Slider slider_t;
Track track;

boolean pause_flag = true;
int dulation = 300; // 5min
int range = 5; // 5sec
String filename = "data/track.csv";

void setup() {
  size(600, 200);
  println(Arduino.list());

  arduino = new Arduino(this, Arduino.list()[0], 57600);

  cp5 = new ControlP5(this);
  slider_t = cp5.addSlider("t").setPosition(10, height-20).setSize(width-40, 10).setRange(0, 300-5).setValue(300-5);

  track = new Track(dulation * 1000, -0.2f, 5.2f);

  frameRate(60);
}

void clear_recording() {
  track.clear();  
  delay(500);
}

void start_recording() {
  clear_recording();
}

void draw() {
  background(0);

  if (!pause_flag) {
    int analog_val = arduino.analogRead(0);
    float val = analog_val/1023.0 * 5.0;
    track.add(val);
  }

  // draw track data
  long st = (long)(slider_t.getValue());
  noFill();
  stroke(0, 255, 0);
  track.draw(st * 1000, range * 1000);

  // draw vertical lines
  noFill();
  int dx = width / range;
  int ddx = width / range / 10;
  for (int i = 0; i < range; ++i) {
    int x = i * dx;
    stroke(255, 255, 0);
    line(x, 0, x, height);
    for (int j = 2; j < 10; j += 2) {
      stroke(64, 64, 0);
      line(x + ddx * j, 0, x + ddx * j, height);       
    }
    
    fill(0, 255, 0);
    text("" + (st + i), x + 5, 10);
  }

  if (pause_flag == true) {
    fill(0, 255, 0);
    noStroke();
    rect(10, 10, 25, 50);
    rect(40, 10, 25, 50);
  } else {
    fill(255, 0, 0);
    noStroke();
    ellipse(35, 35, 50, 50);
  }

  if (frameCount % 100 == 0) {
    println("frameRate=" + frameRate);
  }
} 

void dispose() {
}

void keyPressed() {
  switch(key) {
  case ' ':
    pause_flag = !pause_flag;
    if (pause_flag == false) {
      start_recording();
    }
    break;
  case 's':
    track.save(filename);
    break;
  case 'l':
    pause_flag = true;
    track.load(filename);
    break;
  case 'c':
    clear_recording();
    break;
  }
}

