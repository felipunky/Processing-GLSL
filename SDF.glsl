#ifdef GL_ES\
precision mediump float;
#endif

uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float iTime;
uniform sampler2D iChannel0;

#define EPS          0.002
#define STEPS          128
#define FAR           30.0
#define PI    acos( -1.0 )
#define TAU  atan(1.0)*8.0
#define HASHSCALE    .1031

mat2 rot( float a )
{
    
    return mat2( cos( a ), -sin( a ),
                sin( a ),  cos( a )
                );
    
}

float hash(float p)
{
    vec3 p3  = fract(vec3(p) * HASHSCALE);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// iq's

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = textureLod( iChannel0, (uv+ 0.5)/256.0, 0.0 ).yx;
    return mix( rg.x, rg.y, f.z );
}

float fbm( in vec3 p )
{
    
    float f = 0.0;
    f += 0.5000 * noise( p ); p *= 2.02;
    f += 0.2500 * noise( p ); p *= 2.03;
    f += 0.1250 * noise( p ); p *= 2.01;
    f += 0.0625 * noise( p );
    f += 0.0125 * noise( p );
    return f / 0.9375;
    
}

float sdBox( vec3 p, vec3 b )
{
    
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    
}

float sdSph( vec3 p )
{
    
    return length( p ) - 1.0;
    
}

// Sign function that doesn't return 0
float sgn(float x) {
    return (x<0.)?-1.:1.;
}

vec2 sgn(vec2 v) {
    return vec2((v.x<0.)?-1.:1., (v.y<0.)?-1.:1.);
}


// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
    p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

float vmax(vec2 v) {
    return max(v.x, v.y);
}

float vmax(vec3 v)
{
    
    return max(max(v.x, v.y), v.z);
    
}

float fMod1( float p, float t )
{
    
    float hal = t * 0.5;
    return mod( p + hal, t ) - hal;
    
}

float fOpUnionStairs(float a, float b, float r, float n)
{
    
    float s = r/n;
    float u = b-r;
    return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2.0 * s)) - s)));
    
}


float fOpDifferenceStairs(float a, float b, float r, float n)
{
    
    return -fOpUnionStairs(-a, b, r, n);
    
}

// We can just call Union since stairs are symmetric.
float fOpIntersectionStairs(float a, float b, float r, float n) {
    return -fOpUnionStairs(-a, -b, r, n);
}

float fOpDifferenceColumns(float a, float b, float r, float n)

{
    a = -a;
    float m = min(a, b);
    //avoid the expensive computation where not needed (produces discontinuity though)
    if ((a < r) && (b < r)) {
        vec2 p = vec2(a, b);
        float columnradius = r*sqrt(2.0)/n/2.0;
        columnradius = r*sqrt(2.0-0.0)/((n-1.0)*2.0+sqrt(2.0));
        
        pR45(p);
        p.y += columnradius;
        p.x -= sqrt(2.0)/2.0*r;
        p.x += -columnradius*sqrt(2.0)/2.0;
        
        if (mod(n,2.0) == 1.0) {
            p.y += columnradius;
        }
        pMod1(p.y,columnradius*2.0);
        
        float result = -length(p) + columnradius;
        result = max(result, p.x);
        result = min(result, a);
        return -min(result, b);
    } else {
        return -m;
    }
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

// Same, but mirror every second cell so they match at the boundaries
float pModMirror1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize,size) - halfsize;
    p *= mod(c, 2.0)*2. - 1.;
    return c;
}

vec2 pModMirror2(inout vec2 p, vec2 size) {
    vec2 halfsize = size*0.5;
    vec2 c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    p *= mod(c,vec2(2.))*2. - vec2(1.);
    return c;
}

// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
    float angle = 2.*PI/repetitions;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a,angle) - angle/2.;
    p = vec2(cos(a), sin(a))*r;
    // For an odd number of repetitions, fix cell index of the cell in -x direction
    // (cell index would be e.g. -5 and 5 in the two halves of the cell):
    if (abs(c) >= (repetitions/2.)) c = abs(c);
    return c;
}

// Repeat in two dimensions
vec2 pMod2(inout vec2 p, vec2 size) {
    vec2 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5,size) - size*0.5;
    return c;
}

// Repeat in three dimensions
vec3 pMod3(inout vec3 p, vec3 size) {
    vec3 c = floor((p + size*0.5)/size);
    p = mod(p + size*0.5, size) - size*0.5;
    return c;
}

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float fBox2(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}

// Cylinder standing upright on the xz plane
float fCylinder(vec3 p, float r, float height) {
    float d = length(p.xz) - r;
    d = max(d, abs(p.y) - height);
    return d;
}

float fBox(vec3 p, vec3 b)
{
    
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
    
}

vec2 map( vec3 p )
{
    
    vec2 pla = vec2( p.y + 2.0 + fbm( p + iTime ) * 0.02, 0.0 );
    vec3 pTem = p;
    pTem.xz = mod( p.xz, 5.0 ) - 2.5;
    vec2 sph = vec2( length( pTem ) - cos( iTime ), 3.0 );
    pMirrorOctant( p.xz, vec2( iTime ) );
    pModMirror2( p.xz, vec2( 10.0, 8.0 ) );
    pModPolar( p.xz, 7.0 );
    p.x = -abs( p.x ) + 3.0;
    p.z = fMod1( p.z, 3.0 );
    p.z = abs( p.z ) + 0.4;
    float box = fBox( vec3( p.x, p.y, p.z ) - vec3( 0.0, -1.0, 0.0 ) , vec3( 0.5, 2.0, 0.5 ) );
    float cyl = fCylinder( p.yxz - vec3( 1.0, 0.0, 0.0 ), 0.5, 0.5 );
    float win = min( box, cyl );
    float wal = fBox2( p.xy, vec2( 0.3, 2.6 ) );
    float uni = fOpDifferenceStairs( wal, win, 0.9, 12.0 );
    pMod1( p.z, 1.0 );
    p.y -= 3.05;
    p.x -= 1.2;
    pR( p.xy, -1.2 );
    vec2 roo = vec2( fBox2( p.xy, vec2( 0.1, 2.1 ) ), 1.0 );
    float s = 1.0;
    
    float d = sdBox(p,vec3(1.0));
    for( int m=0; m<4; m++ )
    {
        vec3 a = mod( p*s, 2.0 )-1.0;
        s *= 2.0;
        vec3 r = 2.0 - 3.0*abs(a);
        float c = sdSph( r )/s;
        d = max(d,-c);
    }
    
    roo = vec2( max( roo.x, d ), 1.0 );
    
    vec2 fin = vec2( uni, 2.0 );
    if( roo.x < fin.x ) fin = roo;
    if( fin.x < pla.x ) pla = fin;
    if( sph.x < pla.x ) pla = sph;
    return pla;
    /*vec2 pla = vec2( p.y + 2.3, 0.0 );
     vec2 sph = vec2( length( p ) - 1.0, 1.0 );
     if( sph.x < pla.x ) pla = sph;
     return pla;*/
    
}

vec3 norm( vec3 p )
{
    
    vec2 e = vec2( EPS, 0.0 );
    return normalize( vec3( map( p + e.xyy ).x - map( p - e.xyy ).x,
                           map( p + e.yxy ).x - map( p - e.yxy ).x,
                           map( p + e.yyx ).x - map( p - e.yyx ).x
                           )
                     );
    
}

float softShadows( vec3 ro, vec3 rd )
{
    
    float res = 1.0;
    for( float t = 0.1; t < 8.0; ++t )
    {
        float h = map( ro + rd * t ).x;
        if( h < EPS ) return 0.0;
        res = min( res, 8.0 * h / t );
        
    }
    
    return res;
}

float ray( vec3 ro, vec3 rd, out float d )
{
    
    vec3 col = vec3( 0.0 );
    float t = 0.0;
    for( int i = 0; i < STEPS; ++i )
    {
        
        d = 0.5 * map( ro + rd * t ).x;
        if( d < EPS || t > FAR ) break;
        t += d;
        
    }
    
    return t;
    
}

vec3 shad( vec3 ro, vec3 rd )
{
    
    float d = 0.0;
    float t = ray( ro, rd, d );
    vec3 p = ro + rd * t;
    vec3 n = norm( p );
    vec3 lig = normalize( vec3( 1.0, 0.8, 0.6 ) );
    vec3 blig = vec3( -lig.x, -lig.y, -lig.z );
    vec3 col = vec3( 0.0 );
    vec3 ref = reflect( rd, n );
    
    float amb = 0.5 + 0.5 * n.y;
    float bac = max( 0.0, 0.5 + 0.2 * dot( blig, n ) );
    float dif = max( 0.0, dot( lig, n ) );
    float sha = softShadows( p, lig );
    float spe = pow( clamp( dot( ref, lig ), 0.0, 1.0 ), 16.0 );
    float speO = pow( clamp( dot( ref, blig ), 0.0, 1.0 ), 16.0 );
    
    col += 0.2 * amb;
    col += 0.4 * dif;
    col += 0.2 * bac;
    col += 0.05 * spe;
    col += 0.05 * speO;
    col += 0.2 * sha;
    col = sqrt( col );
    if( map( p ).y == 0.0 ) col *= vec3( 0.1, 0.2, 0.3 );
    if( map( p ).y == 1.0 ) col *= vec3( 0.6, 0.5, 0.5 );
    if( map( p ).y == 2.0 ) col *= mix( vec3( 2.0 ), vec3( 0.0, 0.1, 0.0 ),
                                       fbm( p * fbm( p * fbm( p ) ) )
                                       );
    
    col *= 8.0 / ( 8.0 + t * t * 0.05 );
    col *= sqrt( col );
    
    return col;
    
}


void main( )
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = ( -iResolution.xy + 2.0 * gl_FragCoord.xy ) / iResolution.y;
    
    vec2 mou = iMouse.xy / iResolution.xy;
    mou.y = clamp( mou.y,-TAU/4.0, 1.5 );
    
    vec3 ro = vec3( 0.0 );
    if( mou.x == 0.0 )
        ro = 5.0 * vec3( sin( -2.0 + iTime * 0.2 ), mou.y, cos( 2.0 + iTime * 0.2 ) );
    else if( mou.x != 0.0 )
        ro = 5.0 * vec3( sin( mou.x * PI * 2.0 ), mou.y, cos( -mou.x * PI * 2.0 ) );
    vec3 ww = normalize( vec3( 0.0 ) - ro );
    vec3 uu = normalize( cross( vec3( 0.0, 1.0, 0.0 ), ww ) );
    vec3 vv = normalize( cross( ww, uu ) );
    vec3 rd = normalize( uv.x * uu + uv.y * vv + 1.5 * ww );
    //vec3 rd = normalize( vec3( uv, -1.0 ) );
    
    float d = 0.0;
    float t = ray( ro, rd, d );
    vec3 p = ro + rd * t;
    vec3 n = norm( p );
    
    vec3 col = d < EPS ? shad( ro, rd ) : vec3( 0.0 );
    
    if( map( p ).y == 0.0 || map( p ).y == 3.0 )
        
        rd = normalize( reflect( rd, n ) );
    ro = p + rd * 0.02;
    
    if( d < EPS )
        col += shad( ro, rd );
    
    col *= sqrt( col * 0.5 );
    
    // Output to screen
    gl_FragColor = vec4(col,1.0);
}
