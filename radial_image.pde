import processing.pdf.*;
import java.util.Iterator;

PImage IMG;
float R_INC = 4;
int LINECOUNT = 3;
PVector OFFSET;
float MAX_WIDTH = 3;

void settings() {
  size(500,500);
}

void setup() {
  String frameWord = "image-" + timestamp() + ".pdf";
  beginRecord(PDF, frameWord);
    background(255);
    noFill();
    strokeWeight(1);
    smooth();
    
    IMG = loadImage("plant3.jpg");
    OFFSET = new PVector(height/2, width/2);
    Radial r = new Radial(2);
    r.display();
  endRecord();
}


class Radial {
  ArrayList<Ring> rings;
  float startR;
  float endR;
  
  Radial(float startR_) {
    startR = startR_;
    endR = width/2;
    rings = new ArrayList<Ring>();
  }
  
  void createRings() {
    for(float i = startR; i <= endR; i += R_INC) {
      rings.add(new Ring(i));
    }
  }
  
  void display() {
    createRings();
    Iterator<Ring> it = rings.iterator();
    while(it.hasNext()){
      it.next().display();
    }
  }
}

class Ring {
  float startAngle; // maybe redundant
  float endAngle; // these may be redundant
  float startNoise;
  float r;
  float resolution;
  
  ArrayList<RingVector> ringVectors;
  ArrayList<ArrayList> ringCoords;
  
  Ring(float r_) {
    r = r_;
    startAngle = 0;
    endAngle = 2 * PI;
    resolution = asin(1/r); // this is equivalent to a 1 pixel resolution (may be worth it to adjust this figure)
  }
  
  void createRingVectors() {
    ringVectors = new ArrayList<RingVector>();
    
    for (float i = startAngle; i <= endAngle; i += resolution) {
      float x = cos(i) * r;
      float y = sin(i) * r; // not adding noise yet, this will be an improvement to add.
      PVector point = new PVector(x,y);
      point.add(OFFSET);
      
      float shadeWidth = calculateShading(point);
      RingVector rv = new RingVector(point, shadeWidth);
      ringVectors.add(rv);
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
        println(PVector.lerp(baseCoord, perpVector, i));
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
