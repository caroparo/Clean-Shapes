precision highp float;

#define SMOOTHNESS 1.0

//Shared
varying vec2  v_vOutputTexel;
varying vec2  v_vPosition;
varying float v_fMode;
varying vec4  v_vFillColour;
varying float v_fBorderThickness;
varying vec4  v_vBorderColour;
varying float v_fRounding;
varying float v_fBorder;

//Circle
varying vec2 v_vCircleRadius;
varying vec2 v_vCircleCoord;
varying vec4 v_vCircleInnerColour;

//Rectangle
varying vec2 v_vRectangleXY;
varying vec2 v_vRectangleWH;

float CircleDistance(vec2 p, vec2 ab)
{
    // symmetry
    p = abs( p );
    
    // determine in/out and initial omega value
    bool s = dot(p/ab,p/ab)>1.0;
    float w = s ? atan(p.y*ab.x, p.x*ab.y) : 
                  ((ab.x*(p.x-ab.x)<ab.y*(p.y-ab.y))? 1.5707963 : 0.0);
    
    // find root with Newton solver
    for( int i=0; i<4; i++ )
    {
        vec2 cs = vec2(cos(w),sin(w));
        vec2 u = ab*vec2( cs.x,cs.y);
        vec2 v = ab*vec2(-cs.y,cs.x);
        w = w + dot(p-u,v)/(dot(p-u,u)+dot(v,v));
    }
    
    // compute final point and distance
    return length(p-ab*vec2(cos(w),sin(w))) * (s?1.0:-1.0);
}

float RectangleDistance(vec2 pos, vec2 rectCentre, vec2 rectSize, float radius)
{
    pos -= rectCentre;
    
    vec2 vector = abs(pos) - 0.5*rectSize + radius;
    return length(max(vector, 0.0)) + min(max(vector.x, vector.y), 0.0) - radius;
}

float Distance(vec2 position)
{    
    if (v_fMode == 1.0) //Circle
    {
        return CircleDistance(position, v_vCircleRadius);
    }
    else if (v_fMode == 2.0) //Rectangle + Capsule
    {
        return RectangleDistance(position, v_vRectangleXY, v_vRectangleWH, v_fRounding);
    }
    
    return 0.0;
}

vec4 Derivatives(vec2 position)
{
     return vec4(Distance(position - vec2(v_vOutputTexel.x, 0.0)),
                 Distance(position + vec2(v_vOutputTexel.x, 0.0)),
                 Distance(position - vec2(0.0, v_vOutputTexel.y)),
                 Distance(position + vec2(0.0, v_vOutputTexel.y)));    
}

float Feather(float dist, vec4 derivatives, float threshold)
{
    return clamp(1.0 + ((dist - threshold) / (SMOOTHNESS*length(dist - derivatives))), 0.0, 1.0);
}



void main()
{
    if (v_fMode <= 0.0)
    {
        gl_FragColor = v_vFillColour;
    }
    else
    {
        vec2 position = v_vPosition;
        vec4 fillColour = v_vFillColour;
        
        if (v_fMode == 1.0) // Circle
        {
            position = v_vCircleCoord;
            fillColour = mix(v_vCircleInnerColour, v_vFillColour, length(position/v_vCircleRadius));
        }
        
        float dist = Distance(position);
        vec4  derivatives = Derivatives(position);
        
        vec4 borderColour = fillColour;
        if (v_fBorder < .5) // Border
        {
            borderColour = mix(v_vBorderColour, fillColour, Feather(-dist, -derivatives, v_fBorderThickness));
        }
        
        borderColour.a *= 1.0 - Feather(dist, derivatives, 0.0); // Edge alpha
        gl_FragColor = borderColour;
    }
}