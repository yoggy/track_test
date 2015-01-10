import java.util.*;

class KeyFrame {
  public long t; 
  public float val;
  
  public KeyFrame(long t, float val) {
    this.t = t;
    this.val = val;
  }
}

class Track {
  List l;
  int duration; // ms
  long lastest_add_t;
  long offset_t;
  float min_y, max_y;
  float st_val;
  long st_t;

  Track(int duration, float min_y, float max_y) {
    this.l = new LinkedList();
    this.duration = duration;
    this.min_y = min_y;
    this.max_y = max_y;
  }

  void clear() {
    l.clear();
    lastest_add_t = 0;
    st_val = 0;
    st_t = 0;
  }

  void add(long t, float val) {
    KeyFrame kf = new KeyFrame(t, val);
    lastest_add_t = t;
    l.add(kf);

    gc();
  }

  void add(float val) {
    long t = System.currentTimeMillis();
    add(t, val);
  }

  void gc() {
    Iterator it = l.iterator();
    while(it.hasNext()) {
      KeyFrame kf = (KeyFrame)it.next();
      if (kf.t < st()) {
        it.remove();
        st_t = kf.t;
        st_val = kf.val;
      }
      else {
        break;
      }
    }
  }
  
  long st() {
    return lastest_add_t - duration;
  }

  long et() {
    return lastest_add_t;
  }
  
  boolean is_inner(long t, long st, long et) {
    if (et < st) return false;
    if (t < st || et < t) return false;
    return true;
  }
  
  KeyFrame get_keyframe_by_idx(int idx) {
    return (KeyFrame)l.get(idx);
  }
  
  float get_abs_t(long t) {
    if (is_inner(t, st(), et()) == false) return 0.0f;
    if (l.size() < 2) return 0.0f;

    if (is_inner(t, st(), get_keyframe_by_idx(0).t)) {
      return st_val;
    }
    
    int idx0 = 0;
    int idx1 = l.size() - 1;

    while(idx1 - idx0 >= 1) {
      int idx_m = (idx1 - idx0) / 2 + idx0;
      
      if (idx_m == idx0) break;

      if (is_inner(t, get_keyframe_by_idx(idx0).t, get_keyframe_by_idx(idx_m).t)) {
        idx1 = idx_m;
      }
      else {
        idx0 = idx_m;
      }
    }
    
    KeyFrame kf0 = get_keyframe_by_idx(idx0);
    KeyFrame kf1 = get_keyframe_by_idx(idx1);

    float val = kf0.val;
    if (kf1.t == t) {
      val = kf1.val;
    }
    return val;
  }

  float get_t(long t) {
    long abs_t = t + st();
    return get_abs_t(abs_t);
  }

  // p range is 0.0-1.0
  float get_p(float p) {
    if (p < 0.0f || 1.0f < p) return 0.0f;
    
    long t = st() + (long)(duration * p);
    return get_abs_t(t);
  }

  int get_p_y(float p) {
    float val = get_p(p);
    float y = (1.0f - (val - min_y) / (max_y - min_y)) * height;
    return (int)y;
  }
  
  void draw() {
    draw(st(), duration);
  }
  
  void draw(long st, long d) {
    if (st < 0) {
      st = duration + st;
    }
        
    float sp = st / (float)duration;
    float ep = (st + d) / (float)duration;
    
    int y0 = get_p_y(sp);
    int step = 1;

    stroke(0,255,0);

    for (int x = step; x <= width; x+=step) {
      float p = x / (float)width;
      float tp = (ep - sp) * p + sp;
      
      int y1 = get_p_y(tp);
      
      line(x - step, y0, x , y1);
      y0 = y1;
    }
  }

  boolean load(String filename) {
    clear();
    
    Table table = loadTable(filename, "header");
    if (table == null) {
      println("Track.load() failed...filename=" + filename);
      return false;
    }
    
    for (TableRow row : table.rows()) {
      String t_str = row.getString("t");
      String val_str = row.getString("val");
      
      long t = Long.parseLong(t_str);
      float val = Float.parseFloat(val_str);
      
      add(t, val);
    }
    
    println("Track.load() success...filename=" + filename);

    return true;
  }
  
  boolean save(String filename) {
    if (l.size() == 0) {
      println("Track.load() failed...l.size() is zero...filename=" + filename);
      return false;
    }
    
    Table table = new Table();
    table.addColumn("t");
    table.addColumn("val");
    
    for (int i = 0; i < l.size(); ++i) {
      TableRow row = table.addRow();
      KeyFrame kf = (KeyFrame)l.get(i);
      row.setString("t", Long.toString(kf.t));
      row.setString("val", Float.toString(kf.val));
    }
    
    saveTable(table, filename);
    
    println("Track.save() success...filename=" + filename);
    
    return true;
  }
}
