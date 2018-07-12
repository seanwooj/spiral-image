import processing.pdf.*;
import java.util.Iterator;

PImage IMG;
float RES_DIVISOR = 1.2;
int LINECOUNT = 3;
PVector OFFSET;
float MAX_WIDTH = 2.3;
float STROKE = 3;
String FILENAME = "butt2";

// MAX WIDTH VALUES
// 3 IS GOOD FOR SHARPIE FINELINER
// Uniball Air
// Res mult: .66
// MaxWidth: 2.1

void settings() {
  size(500,500);
}

void setup() {
  String frameWord = "output/image-" + timestamp() + ".pdf";
  beginRecord(PDF, frameWord);
    background(255);
    noFill();
    strokeWeight(STROKE);
    smooth();
    String filename = "input/" + FILENAME + ".jpg";
    IMG = loadImage(filename);
    OFFSET = new PVector(height/2, width/2);
    Ring r = new Ring(1);
    r.display();
  endRecord();
}

class Ring {
  float startNoise;
  float startR;
  float currentR;
  float resolution;
  float rInc;
  
  ArrayList<RingVector> ringVectors;
  ArrayList<ArrayList> ringCoords;
  
  Ring(float startR_) {
    startR = startR_;
  }
  
  void createRingVectors() {
    ringVectors = new ArrayList<RingVector>();
    resolution = asin(1/currentR);
    float i = 0;
    for (currentR = startR; currentR <= width/2; currentR += (resolution / RES_DIVISOR)) {
      resolution = asin(1/currentR);
      float x = cos(i) * currentR;
      float y = sin(i) * currentR; // not adding noise yet, this will be an improvement to add.
      PVector point = new PVector(x,y);
      point.setMag(point.mag() + noise((i/resolution) / 50) * 2);
      point.add(OFFSET);
      
      float shadeWidth = calculateShading(point);
      RingVector rv = new RingVector(point, shadeWidth);
      ringVectors.add(rv);
      i += resolution;
    }
    
    calculateRingVectors();
    createArrays();
  }
  
  float calculateShading(PVector loc) {
    int x = Math.round(loc.x);
    int y = Math.round(loc.y);
    color c = IMG.get(x, y);
    float b = brightness(c);
    return map(b, 255, 0, 0, MAX_WIDTH);
  }
  
   void calculateRingVectors(){
    RingVector prev = null;
    Iterator<RingVector> it = ringVectors.iterator();
    while(it.hasNext()){
      RingVector current = it.next();
      current.calculateVectors(prev);
      prev = current;
    }
  }
  
  void createArrays() {
    // instantiate the array of arrays
    ringCoords = new ArrayList<ArrayList>();
    
    // fill in array positions with pvector arrays
    for(int i = 0; i < LINECOUNT; i++) {
      ringCoords.add(new ArrayList<PVector>());
    }
    
    Iterator<RingVector> it = ringVectors.iterator();
    while(it.hasNext()){
      RingVector rv = it.next();
      for(int i = 0; i < LINECOUNT; i++) {
        ringCoords.get(i).add(rv.vectors.get(i));
      }
    }
  }
  
  void display() {
    createRingVectors();
    Iterator<ArrayList> it = ringCoords.iterator();
    while(it.hasNext()) {
      ArrayList<PVector> coords = it.next();
      Iterator<PVector> pvit = coords.iterator();
      beginShape();
        while(pvit.hasNext()){
          PVector loc = pvit.next();
          vertex(loc.x, loc.y);
        }
      endShape();
    }
  }
  
  void displayRingVectorPoints() {
    Iterator<RingVector> it = ringVectors.iterator();
    while(it.hasNext()){
      it.next().displayPoints();
    }
  }
}

class RingVector {
  ArrayList<PVector> vectors;
  float thickness;
  PVector baseCoord;
  int lineCount;
  
  RingVector(PVector baseCoord_, float thickness_) {
    baseCoord = baseCoord_;
    thickness = thickness_;
    lineCount = LINECOUNT;
    vectors = new ArrayList<PVector>();
  }
  
  void displayPoints(){
    Iterator<PVector> it = vectors.iterator();

    while(it.hasNext()){
      PVector v = it.next();
      point(v.x, v.y);
    }
    
  }
  
  void calculateVectors(RingVector prev) {
    if (prev == null) {
      // set to origin for now, but this should do something better eventually.
      for(int i = 0; i < lineCount; i++) {
        vectors.add(baseCoord);
      }
    } else {
      // get the base coordinate from the previous ringVec
      PVector prevBase = prev.baseCoord;
      // get the base directional vector by subtracting the previous loci from the current loci
      PVector directionalVector = baseCoord.copy().sub(prevBase);
      // rotate the directional by 90 degrees to get the perpendicular vector
      PVector perpVector = directionalVector.copy().rotate(-HALF_PI);
      // get the outer value of the thickness from the center point to use as the outer bands in the lerp
      float endPoint = thickness/2; // rename
      // how much should the iteration increase per loop
      // since we are using -1 to 1 as the values in our lerp (negative being the start, positive being the end)
      // the incrementer is the value to use in the loops as we calculate the lerp
      float incrementer = ( 2 / (lineCount - 1.0) );
      // set the magnitude of the perpendicular vector to the endpoint value, such that when we call lerp()
      // a lerp of 1 will calculate the final point in the array.
      perpVector.setMag(endPoint).add(baseCoord);
      
      for(float i = -1; i <= 1; i += incrementer) {
        //println(PVector.lerp(baseCoord, perpVector, i));
        vectors.add(PVector.lerp(baseCoord, perpVector, i));
      }
      
    }
  }
}


String timestamp() {
  int[] dateNumbers = new int[6];
  dateNumbers[0] = year();
  dateNumbers[1] = month();
  dateNumbers[2] = day();
  dateNumbers[3] = hour();
  dateNumbers[4] = minute();
  dateNumbers[5] = second();

  String joinedTimestamp = join(nf(dateNumbers, 2), "");

  return joinedTimestamp;
}
