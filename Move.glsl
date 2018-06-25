#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;
uniform float iForward;
uniform float iSide;
uniform float iUp;
uniform vec2 iFractal;
uniform bool iMSAA;

#define EPS      0.0002
#define STEPS       256
#define FAR        50.0
#define PI acos( -1.0 )
#define TPI    PI * 2.0

const float f = 1.0;
const int samples = 2;

mat2 rot( float a )
{
    
    return mat2( cos( a ), -sin( a ),
                 sin( a ),  cos( a )
                );
    
}

vec3 pMod3( inout vec3 p, float s )
{
    
    vec3 a = mod( p*s, 2.0 )-1.0;
    return a;
    
}

// Sign function that doesn't return 0
float sgn(float x) {
    return (x<0.)?-1.:1.;
}

vec2 sgn(vec2 v) {
    return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
    float s = sgn(p);
    p = abs(p)-dist;
    return s;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
vec2 pMirrorOctant (inout vec2 p, vec2 dist) {
    vec2 s = sgn(p);
    pMirror(p.x, dist.x);
    pMirror(p.y, dist.y);
    if (p.y > p.x)
        p.xy = p.yx;
    return s;
}


float sdBox( vec3 p, vec3 b )
{
    
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    
}

float sph( vec3 p, float r )
{
    
    return length( p ) - r;
    
}

float map ( vec3 p, out vec3 tra )
{
    
    pMirrorOctant( p.xz, vec2( 0.8, 1.0 ) );
    pMirrorOctant( p.xy, vec2( 0.2, 0.5 ) );
    p = pMod3( p, ( 0.3 ) );
    float box = sdBox( p, vec3( 1.0 ) );
    float sp = sph( p, 1.2 );
    float s = 1.0;
    float obj = max( -sp, box );
    float d = sdBox(p,vec3(1.0));
    
    for( int m=0; m<5; m++ )
    {
        p = abs( p - vec3( 0.1, 0.0, 0.0 ) );
        p.xy = p.yx;
        p.xy *= rot( iFractal.y );
        p.xz *= rot( iFractal.x );
        vec3 a = mod( p*s, 2.0 )-1.0;
        s *= 4.0;
        vec3 r = 1.0 - 3.0*abs(a);
        float c = sph( r, 1.2 )/s;
        d = max(d,-c);
        
        if( c < d )
        {
            
            tra = vec3( d * float( m ) * 3000.0 * sin( iTime * 0.8 ), float( m ), 1.0 );
            
        }
    }
    
    return max( obj, d );
    
}

vec3 norm( vec3 p )
{
    
    vec3 tra = vec3( 0.0 );
    vec2 e = vec2( EPS, 0.0 );
    return normalize( vec3( map( p + e.xyy, tra ) - map( p - e.xyy, tra ),
                            map( p + e.yxy, tra ) - map( p - e.yxy, tra ),
                            map( p + e.yyx, tra ) - map( p - e.yyx, tra )
                           )
                     );
    
}

float ray( vec3 ro, vec3 rd, out float d )
{
    
    float t = 0.0; vec3 tra = vec3( 0.0 ); d = 0.0;
    
    for( int i = 0; i < STEPS; ++i )
    {
        
        d = map( ro + rd * t, tra );
        if( d < EPS || t > FAR ) break;
        
        t += d;
        
    }
    
    return t;
    
}

float softShadows( in vec3 ro, in vec3 rd )
{
    
    vec3 tra = vec3( 0.0 );
    float res = 1.0;
    for( float t = 0.1; t < 8.0; ++t )
    {
        
        float h = map( ro + rd * t, tra );
        res = min( res, 8.0 * h / t );
        
    }
    
    return res;
    
}

vec3 shad( vec3 ro, vec3 rd )
{
    
    float d = 0.0, t = ray( ro, rd, d );
    vec3 p = ro + rd * t;
    vec3 n = norm( p );
    vec3 lig = normalize( vec3( 1.0, 0.8, 0.6 ) );
    vec3 blig = vec3( -lig.x, -lig.y, -lig.z );
    vec3 col = vec3( 0.0 );
    vec3 tra = vec3( 1.0 );
    vec3 ref = reflect( rd, n );
    
    float ma = map( p, tra );
    float amb = 0.5 + 0.5 * n.y;
    float dif = max( 0.0, dot( lig, n ) );
    float bac = max( 0.0,  0.5 * dot( blig, n ) );
    float sha = softShadows( p, lig );
    float spe = pow( clamp( dot( lig, ref ), 0.0, 1.0 ), 16.0 );
    float speO = pow( clamp( dot( blig, ref ), 0.0, 1.0 ), 16.0 );
    
    col += 1.2 * amb;
    col += dif;
    col += bac * sha;
    col += 1.0 * spe + 1.0 * speO;
    col += mix( vec3( 0.0 ), vec3( 0.0, 0.5, 0.0 ), tra.x );
    col += mix( vec3( 1.0 ), vec3( 0.6, 0.0, 0.0 ), tra.y );
    if( col.r > 0.5 && col.g > 0.5 && col.b > 0.5 ) col *= vec3( 0.2, 0.3, 0.1 );
    //col += texture( iChannel1, normalize( reflect( rd, n ) ) ).rgb * 0.2;
    col *= sqrt( col );
    return col;
    
}

void main( )
{
    
    vec2 uv = ( -iResolution.xy + 2.0 * gl_FragCoord.xy ) / iResolution.y;
    
    vec2 mou = vec2( -iMouse.x, iMouse.y );
    
    vec3 ro = vec3( iSide, iUp, -iForward );
    vec3 rd = normalize( vec3( uv, -1.0 ) );
    
    ro.zy *= rot( mou.x );
    ro.xz *= rot( mou.y );

    rd.zy *= rot( mou.x );
    rd.xz *= rot( mou.y );

    vec3 tra = vec3( 0.0 );
    
    float d = 0.0, t = ray( ro, rd, d );
    
    vec3 p = ro + rd * t;
    
    vec3 col = vec3( 0 );
    
    if( iMSAA == true )
    {
        
        vec3 ww = normalize( ro );
        vec3 uu = normalize( cross( vec3( 0.0, 1.0, 0.0 ), ww ) );
        vec3 vv = normalize( cross( ww, uu ) );
        for (int x = - samples / 2; x < samples / 2; x++) {
            for (int y = - samples / 2; y < samples / 2; y++) {
                vec3 rd = normalize(
                                    (float(x) / iResolution.y - uv.x)*uu +
                                    (float(y) / iResolution.y + uv.y)*vv +
                                    f*ww );
                t = ray(ro, rd, d);
                col += d < EPS ? shad( ro, rd ) : mix( vec3( 1.0 ), vec3( 0.4, 0.2, 0.1 ), uv.y );
            }
        }
        
        gl_FragColor = vec4( col / float(samples * samples), 1.0 );
        
    }
    
    else if( iMSAA == false )
    {
        
        col = d < EPS ? shad( ro, rd ) : mix( vec3( 1.0 ), vec3( 0.4, 0.2, 0.1 ), uv.y );
        
        // Output to screen
        gl_FragColor = vec4(col,1.0);
        
    }
    
}
