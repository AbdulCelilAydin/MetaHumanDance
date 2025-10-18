/*
Shader: Custom/ChromaLerp4_Surface
Açýklama:
- Arkaplaný yeþil olan 4 adet texture'ý chroma-key (green threshold) ile anahtarlayýp
  birbirleri arasýnda zamanla lerp ederek (video gibi) oynatýr.
- Surface shader (Standard lighting) kullanýr, alpha ile fade/transparent output üretir.
Kullaným:
- Material yaratýp bu shader'ý ata.
- _MainTex1..4 alanlarýna görselleri sürükle.
- _Threshold: yeþil ayýrma eþik deðeri (0..1). Deðer arttýkça daha az renk silinir.
- _Feather: kenar yumuþatma (0..0.5).
- _Speed: oynatma hýzý.
- Shader alpha üretir — material Rendering Mode "Fade"/"Transparent" ayarlarýyla doðru davranýr.
*/

Shader "Custom/ChromaLerp4_Surface" {
    Properties
    {
    _Tex1 ("Texture 1", 2D) = "white" {}
    _Tex2 ("Texture 2", 2D) = "white" {}
    _Tex3 ("Texture 3", 2D) = "white" {}
    _Tex4 ("Texture 4", 2D) = "white" {}
    _Speed ("Playback Speed", Range(0,10)) = 2
    _GreenThreshold ("Green Threshold", Range(0,1)) = 0.35
    _Feather ("Feather", Range(0,0.5)) = 0.1
    }


    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="AlphaTest" }
        LOD 200


        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alpha:fade


        sampler2D _Tex1;
        sampler2D _Tex2;
        sampler2D _Tex3;
        sampler2D _Tex4;
        float _Speed;
        float _GreenThreshold;
        float _Feather;


        struct Input
        {
        float2 uv_Tex1;
        };


        fixed4 SampleTex(float index, float2 uv)
        {
        if (index < 0.5) return tex2D(_Tex1, uv);
        else if (index < 1.5) return tex2D(_Tex2, uv);
        else if (index < 2.5) return tex2D(_Tex3, uv);
        else return tex2D(_Tex4, uv);
        }


        void surf (Input IN, inout SurfaceOutputStandard o)
        {
        float2 uv = IN.uv_Tex1;
        float t = frac(_Time.y * _Speed * 0.25); // 0..1
        float frame = t * 4.0;
        float idx = floor(frame);
        float next = fmod(idx + 1.0, 4.0);
        float f = frame - idx;


        fixed4 colA = SampleTex(idx, uv);
        fixed4 colB = SampleTex(next, uv);
        fixed4 col = lerp(colA, colB, f);


        // Green screen mask
        float nongreen = max(col.r, col.b);
        float gdiff = col.g - nongreen;
        float lower = _GreenThreshold - _Feather;
        float upper = _GreenThreshold + _Feather;
        float mask = smoothstep(lower, upper, gdiff);
        float alpha = 1.0 - mask;


        clip(alpha - 0.01);


        o.Albedo = col.rgb;
        o.Alpha = alpha;
        }
    ENDCG
    }


FallBack "Transparent/Cutout/VertexLit"
}
