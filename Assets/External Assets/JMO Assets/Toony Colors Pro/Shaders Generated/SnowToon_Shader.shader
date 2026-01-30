// Toony Colors Pro+Mobile 2
// (c) 2014-2023 Jean Moreno

Shader "Toony Colors Pro 2/User/My TCP2 Shader"
{
	Properties
	{
		[Enum(Front, 2, Back, 1, Both, 0)] _Cull ("Render Face", Float) = 2.0
		[TCP2ToggleNoKeyword] _ZWrite ("Depth Write", Float) = 1.0
		[HideInInspector] _RenderingMode ("rendering mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("blending source", Float) = 1.0
		[HideInInspector] _DstBlend ("blending destination", Float) = 0.0
		[TCP2Separator]

		[TCP2HeaderHelp(Base)]
		[HDR] _BaseColor ("Color", Color) = (1,1,1,1)
		[TCP2ColorNoAlpha] _HColor ("Highlight Color", Color) = (0.75,0.75,0.75,1)
		[TCP2ColorNoAlpha] _SColor ("Shadow Color", Color) = (0.2,0.2,0.2,1)
		[MainTexture] _BaseMap ("Albedo", 2D) = "white" {}
		[TCP2Separator]

		[TCP2Header(Ramp Shading)]
		
		_RampThreshold ("Threshold", Range(0.01,1)) = 0.5
		_RampSmoothing ("Smoothing", Range(0.001,1)) = 0.5
		[IntRange] _BandsCount ("Bands Count", Range(1,20)) = 4
		_BandsSmoothing ("Bands Smoothing", Range(0.001,1)) = 0.1
		[TCP2Separator]
		
		[TCP2HeaderHelp(Specular)]
		[Toggle(TCP2_SPECULAR)] _UseSpecular ("Enable Specular", Float) = 0
		[TCP2ColorNoAlpha] _SpecularColor ("Specular Color", Color) = (0.5,0.5,0.5,1)
		_SpecularSmoothness ("Smoothness", Float) = 0.2
		_AnisotropicSpread ("Anisotropic Spread", Range(0,2)) = 1
		_SpecularToonSize ("Toon Size", Range(0,1)) = 0.25
		_SpecularToonSmoothness ("Toon Smoothness", Range(0.001,0.5)) = 0.05
		[TCP2Separator]

		[TCP2HeaderHelp(Emission)]
		[TCP2ColorNoAlpha] [HDR] _Emission ("Emission Color", Color) = (0,0,0,1)
		[TCP2Separator]
		
		[TCP2HeaderHelp(Rim Lighting)]
		[Toggle(TCP2_RIM_LIGHTING)] _UseRim ("Enable Rim Lighting", Float) = 0
		[TCP2ColorNoAlpha] _RimColor ("Rim Color", Color) = (0.8,0.8,0.8,0.5)
		_RimMin ("Rim Min", Range(0,2)) = 0.5
		_RimMax ("Rim Max", Range(0,2)) = 1
		[TCP2Separator]
		
		[TCP2HeaderHelp(Normal Mapping)]
		[Toggle(_NORMALMAP)] _UseNormalMap ("Enable Normal Mapping", Float) = 0
		[NoScaleOffset] _BumpMap ("Normal Map", 2D) = "bump" {}
		[TCP2Separator]
		
		[TCP2ColorNoAlpha] _DiffuseTint ("Diffuse Tint", Color) = (1,0.5,0,1)
		[TCP2Separator]
		
		[TCP2HeaderHelp(Sketch)]
		[Toggle(TCP2_SKETCH)] _UseSketch ("Enable Sketch Effect", Float) = 0
		_SketchTexture ("Sketch Texture", 2D) = "black" {}
		_SketchTexture_OffsetSpeed ("Sketch Texture UV Offset Speed", Float) = 120
		_SketchMin ("Sketch Min", Range(0,1)) = 0
		_SketchMax ("Sketch Max", Range(0,1)) = 1
		[TCP2Separator]
		
		[TCP2Vector4Floats(Contrast X,Contrast Y,Contrast Z,Smoothing,1,16,1,16,1,16,0.05,10)] _TriplanarSamplingStrength ("Triplanar Sampling Parameters", Vector) = (8,8,8,0.5)
		
		[TCP2Separator]
		[TCP2HeaderHelp(MATERIAL LAYERS)]

		[TCP2Separator]
		[TCP2Header(Snow)]
		_NormalThreshold_snow ("Normal Threshold", Float) = 1
		_contrast_snow ("Contrast", Range(0,1)) = 0.5
		_NoiseTexture_snow ("Noise Texture", 2D) = "gray" {}
		 _NoiseStrength_snow ("Noise Strength", Range(0,1)) = 0.1
		[MainTexture] _BaseMap_snow ("Albedo", 2D) = "white" {}
		[HDR] _BaseColor_snow ("Color", Color) = (1,1,1,1)
		[TCP2ColorNoAlpha] _SpecularColor_snow ("Specular Color", Color) = (0.5,0.5,0.5,1)
		_SketchTexture_snow ("Sketch Texture", 2D) = "black" {}
		_SketchTexture_snow_OffsetSpeed ("Sketch Texture UV Offset Speed", Float) = 120
		
		_SketchMin_snow ("Sketch Min", Range(0,1)) = 0
		_SketchMax_snow ("Sketch Max", Range(0,1)) = 1

		[ToggleOff(_RECEIVE_SHADOWS_OFF)] _ReceiveShadowsOff ("Receive Shadows", Float) = 1

		// Avoid compile error if the properties are ending with a drawer
		[HideInInspector] __dummy__ ("unused", Float) = 0
	}

	SubShader
	{
		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType"="Opaque"
		}

		HLSLINCLUDE
		#define fixed half
		#define fixed2 half2
		#define fixed3 half3
		#define fixed4 half4

		#if UNITY_VERSION >= 202020
			#define URP_10_OR_NEWER
		#endif
		#if UNITY_VERSION >= 202120
			#define URP_12_OR_NEWER
		#endif
		#if UNITY_VERSION >= 202220
			#define URP_14_OR_NEWER
		#endif

		// Texture/Sampler abstraction
		#define TCP2_TEX2D_WITH_SAMPLER(tex)						TEXTURE2D(tex); SAMPLER(sampler##tex)
		#define TCP2_TEX2D_NO_SAMPLER(tex)							TEXTURE2D(tex)
		#define TCP2_TEX2D_SAMPLE(tex, samplertex, coord)			SAMPLE_TEXTURE2D(tex, sampler##samplertex, coord)
		#define TCP2_TEX2D_SAMPLE_LOD(tex, samplertex, coord, lod)	SAMPLE_TEXTURE2D_LOD(tex, sampler##samplertex, coord, lod)

		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

		// Uniforms

		// Shader Properties
		TCP2_TEX2D_WITH_SAMPLER(_BumpMap);
		TCP2_TEX2D_WITH_SAMPLER(_BaseMap);
		TCP2_TEX2D_WITH_SAMPLER(_BaseMap_snow);
		TCP2_TEX2D_WITH_SAMPLER(_SketchTexture);
		TCP2_TEX2D_WITH_SAMPLER(_SketchTexture_snow);
		TCP2_TEX2D_WITH_SAMPLER(_NoiseTexture_snow);

		CBUFFER_START(UnityPerMaterial)
			
			// Shader Properties
			float4 _BaseMap_ST;
			float4 _BaseMap_snow_ST;
			half4 _BaseColor;
			half4 _BaseColor_snow;
			half4 _Emission;
			float _RampThreshold;
			float _RampSmoothing;
			float _BandsCount;
			float _BandsSmoothing;
			fixed4 _DiffuseTint;
			float _RimMin;
			float _RimMax;
			fixed4 _RimColor;
			float _AnisotropicSpread;
			float _SpecularSmoothness;
			float _SpecularToonSize;
			float _SpecularToonSmoothness;
			fixed4 _SpecularColor;
			fixed4 _SpecularColor_snow;
			float4 _SketchTexture_ST;
			half _SketchTexture_OffsetSpeed;
			float4 _SketchTexture_snow_ST;
			half _SketchTexture_snow_OffsetSpeed;
			float _SketchMin;
			float _SketchMin_snow;
			float _SketchMax;
			float _SketchMax_snow;
			fixed4 _SColor;
			fixed4 _HColor;
			float _NormalThreshold_snow;
			float _contrast_snow;
			float4 _NoiseTexture_snow_ST;
			float _NoiseStrength_snow;
			float4 _TriplanarSamplingStrength;
		CBUFFER_END

		// Texture sampling with triplanar UVs
		float4 tex2D_triplanar(sampler2D samp, float4 tiling_offset, float3 worldPos, float3 worldNormal)
		{
			half4 sample_y = ( tex2D(samp, worldPos.xz * tiling_offset.xy + tiling_offset.zw).rgba );
			fixed4 sample_x = ( tex2D(samp, worldPos.zy * tiling_offset.xy + tiling_offset.zw).rgba );
			fixed4 sample_z = ( tex2D(samp, worldPos.xy * tiling_offset.xy + tiling_offset.zw).rgba );
			
			// blending
			half3 blendWeights = pow(abs(worldNormal), _TriplanarSamplingStrength.xyz / _TriplanarSamplingStrength.w);
			blendWeights = blendWeights / (blendWeights.x + abs(blendWeights.y) + blendWeights.z);
			half4 triplanar = sample_x * blendWeights.x + sample_y * blendWeights.y + sample_z * blendWeights.z;
			
			return triplanar;
		}
			
		// Version with separate texture and sampler
		#define TCP2_TEX2D_SAMPLE_TRIPLANAR(tex, samplertex, tiling, positionWS, normalWS) tex2D_triplanar(tex, sampler##samplertex, tiling, positionWS, normalWS)
		float4 tex2D_triplanar(Texture2D tex, SamplerState samp, float4 tiling_offset, float3 worldPos, float3 worldNormal)
		{
			half4 sample_y = ( tex.Sample(samp, worldPos.xz * tiling_offset.xy + tiling_offset.zw).rgba );
			fixed4 sample_x = ( tex.Sample(samp, worldPos.zy * tiling_offset.xy + tiling_offset.zw).rgba );
			fixed4 sample_z = ( tex.Sample(samp, worldPos.xy * tiling_offset.xy + tiling_offset.zw).rgba );
			
			// blending
			half3 blendWeights = pow(abs(worldNormal), _TriplanarSamplingStrength.xyz / _TriplanarSamplingStrength.w);
			blendWeights = blendWeights / (blendWeights.x + abs(blendWeights.y) + blendWeights.z);
			half4 triplanar = sample_x * blendWeights.x + sample_y * blendWeights.y + sample_z * blendWeights.z;
			
			return triplanar;
		}
		
		// Hash without sin and uniform across platforms
		// Adapted from: https://www.shadertoy.com/view/4djSRW (c) 2014 - Dave Hoskins - CC BY-SA 4.0 License
		float2 hash22(float2 p)
		{
			float3 p3 = frac(p.xyx * float3(443.897, 441.423, 437.195));
			p3 += dot(p3, p3.yzx + 19.19);
			return frac((p3.xx+p3.yz)*p3.zy);
		}
		
		// Built-in renderer (CG) to SRP (HLSL) bindings
		#define UnityObjectToClipPos TransformObjectToHClip
		#define _WorldSpaceLightPos0 _MainLightPosition
		
		ENDHLSL

		Pass
		{
			Name "Main"
			Tags
			{
				"LightMode"="UniversalForward"
			}
		Blend [_SrcBlend] [_DstBlend]
		Cull [_Cull]
		ZWrite [_ZWrite]

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard SRP library
			// All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 3.0

			// -------------------------------------
			// Material keywords
			#pragma shader_feature_local _ _RECEIVE_SHADOWS_OFF

			// -------------------------------------
			// Universal Render Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK

			// -------------------------------------
			#pragma multi_compile_fog

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing

			#pragma vertex Vertex
			#pragma fragment Fragment

			//--------------------------------------
			// Toony Colors Pro 2 keywords
			#pragma shader_feature_local_fragment TCP2_SPECULAR
			#pragma shader_feature_local_fragment TCP2_RIM_LIGHTING
		#pragma shader_feature_local _ _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment TCP2_SKETCH

			// vertex input
			struct Attributes
			{
				float4 vertex       : POSITION;
				float3 normal       : NORMAL;
				float4 tangent      : TANGENT;
				float4 texcoord0 : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			// vertex output / fragment input
			struct Varyings
			{
				float4 positionCS     : SV_POSITION;
				float3 normal         : NORMAL;
				float4 worldPosAndFog : TEXCOORD0;
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord    : TEXCOORD1; // compute shadow coord per-vertex for the main light
			#endif
			#ifdef _ADDITIONAL_LIGHTS_VERTEX
				half3 vertexLights : TEXCOORD2;
			#endif
				float4 pack0 : TEXCOORD3; /* pack0.xyz = tangent  pack0.w = fogFactor */
				float3 pack1 : TEXCOORD4; /* pack1.xyz = bitangent */
				float2 pack2 : TEXCOORD5; /* pack2.xy = texcoord0 */
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings Vertex(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				// Texture Coordinates
				output.pack2.xy.xy = input.texcoord0.xy * _BaseMap_ST.xy * _BaseMap_snow_ST.xy + _BaseMap_ST.zw + _BaseMap_snow_ST.zw;

				float3 worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				output.shadowCoord = GetShadowCoord(vertexInput);
			#endif

				VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal, input.tangent);
			#ifdef _ADDITIONAL_LIGHTS_VERTEX
				// Vertex lighting
				output.vertexLights = VertexLighting(vertexInput.positionWS, vertexNormalInput.normalWS);
			#endif

				// world position
				output.worldPosAndFog = float4(vertexInput.positionWS.xyz, 0);

				// Computes fog factor per-vertex
				output.worldPosAndFog.w = ComputeFogFactor(vertexInput.positionCS.z);

				// normal
				output.normal = normalize(vertexNormalInput.normalWS);

				// tangent
				output.pack0.xyz = vertexNormalInput.tangentWS;
				output.pack1.xyz = vertexNormalInput.bitangentWS;

				// clip position
				output.positionCS = vertexInput.positionCS;

				return output;
			}

			half4 Fragment(Varyings input
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float3 positionWS = input.worldPosAndFog.xyz;
				float3 normalWS = normalize(input.normal);
				half3 viewDirWS = SafeNormalize(GetCameraPositionWS() - positionWS);
				half3 tangentWS = input.pack0.xyz;
				half3 bitangentWS = input.pack1.xyz;
				#if defined(_NORMALMAP)
				half3x3 tangentToWorldMatrix = half3x3(tangentWS.xyz, bitangentWS.xyz, normalWS.xyz);
				#endif

				// Sampled in Custom Code
				float4 imp_100 = _NoiseStrength_snow;
				// Shader Properties Sampling
				float4 __normalMap = ( TCP2_TEX2D_SAMPLE(_BumpMap, _BumpMap, input.pack2.xy).rgba );
				float4 __albedo = ( TCP2_TEX2D_SAMPLE(_BaseMap, _BaseMap, input.pack2.xy).rgba );
				float4 __albedo_snow = ( TCP2_TEX2D_SAMPLE(_BaseMap_snow, _BaseMap_snow, input.pack2.xy).rgba );
				float3 __highlightColor = ( _HColor.rgb );
				float4 __mainColor = ( _BaseColor.rgba * __highlightColor.rgbr );
				float4 __mainColor_snow = ( _BaseColor_snow.rgba );
				float __alpha = ( __albedo.a * __mainColor.a );
				float __ambientIntensity = ( 1.0 );
				float3 __emission = ( _Emission.rgb );
				float __rampThreshold = ( _RampThreshold );
				float __rampSmoothing = ( _RampSmoothing );
				float __bandsCount = ( _BandsCount );
				float __bandsSmoothing = ( _BandsSmoothing );
				float3 __diffuseTint = ( _DiffuseTint.rgb );
				float __rimMin = ( _RimMin );
				float __rimMax = ( _RimMax );
				float3 __rimColor = ( _RimColor.rgb );
				float __rimStrength = ( 1.0 );
				float __anisotropicSpread = ( _AnisotropicSpread );
				float __specularSmoothness = ( _SpecularSmoothness );
				float __specularToonSize = ( _SpecularToonSize );
				float __specularToonSmoothness = ( _SpecularToonSmoothness );
				float3 __specularColor = ( _SpecularColor.rgb );
				float3 __specularColor_snow = ( _SpecularColor_snow.rgb );
				float3 __sketchTexture = ( TCP2_TEX2D_SAMPLE_TRIPLANAR(_SketchTexture, _SketchTexture, float4(float2(1, 1) * _SketchTexture_ST.xy, _SketchTexture_ST.zw + hash22(floor(_Time.xx * _SketchTexture_OffsetSpeed.xx) / _SketchTexture_OffsetSpeed.xx)), positionWS, normalWS).aaa );
				float3 __sketchTexture_snow = ( TCP2_TEX2D_SAMPLE_TRIPLANAR(_SketchTexture_snow, _SketchTexture_snow, float4(float2(1, 1) * _SketchTexture_snow_ST.xy, _SketchTexture_snow_ST.zw + hash22(floor(_Time.xx * _SketchTexture_snow_OffsetSpeed.xx) / _SketchTexture_snow_OffsetSpeed.xx)), positionWS, normalWS).aaa );
				float __sketchAntialiasing = ( 20.0 );
				float __sketchAntialiasing_snow = ( 20.0 );
				float __sketchThresholdScale = ( 1.0 );
				float __sketchThresholdScale_snow = ( 1.0 );
				float __sketchMin = ( _SketchMin );
				float __sketchMin_snow = ( _SketchMin_snow );
				float __sketchMax = ( _SketchMax );
				float __sketchMax_snow = ( _SketchMax_snow );
				float3 __shadowColor = ( _SColor.rgb );
				float3 __sketchColor = ( float3(0,0,0) );
				float3 __sketchColor_snow = ( float3(0,0,0) );
				float __layer_snow = saturate(  normalWS.y + _NormalThreshold_snow );
				float __contrast_snow = ( _contrast_snow );
				float __noise_snow = (  saturate( TCP2_TEX2D_SAMPLE_TRIPLANAR(_NoiseTexture_snow, _NoiseTexture_snow, float4(1, 1, 1, 1) * _NoiseTexture_snow_ST, positionWS, normalWS).r * imp_100 ) - imp_100 / 2.0 );

				// Material Layers Blending
				 __albedo = lerp(__albedo, __albedo_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));
				 __mainColor = lerp(__mainColor, __mainColor_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));
				 __specularColor = lerp(__specularColor, __specularColor_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));
				 __sketchTexture = lerp(__sketchTexture, __sketchTexture_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));
				 __sketchAntialiasing = lerp(__sketchAntialiasing, __sketchAntialiasing_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));
				 __sketchThresholdScale = lerp(__sketchThresholdScale, __sketchThresholdScale_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));
				 __sketchMin = lerp(__sketchMin, __sketchMin_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));
				 __sketchMax = lerp(__sketchMax, __sketchMax_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));
				 __sketchColor = lerp(__sketchColor, __sketchColor_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));

				#if defined(_NORMALMAP)
				half4 normalMap = __normalMap;
				half3 normalTS = UnpackNormal(normalMap);
					#if defined(_NORMALMAP)
				normalWS = normalize( mul(normalTS, tangentToWorldMatrix) );
					#endif
				#endif

				half ndv = abs(dot(viewDirWS, normalWS));
				half ndvRaw = ndv;

				// main texture
				half3 albedo = __albedo.rgb;
				half alpha = __alpha;

				half3 emission = half3(0,0,0);
				
				albedo *= __mainColor.rgb;

				// main light: direction, color, distanceAttenuation, shadowAttenuation
			#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord = input.shadowCoord;
			#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
				float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
			#else
				float4 shadowCoord = float4(0, 0, 0, 0);
			#endif

			#if defined(URP_10_OR_NEWER)
				#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
					half4 shadowMask = SAMPLE_SHADOWMASK(input.uvLM);
				#elif !defined (LIGHTMAP_ON)
					half4 shadowMask = unity_ProbesOcclusion;
				#else
					half4 shadowMask = half4(1, 1, 1, 1);
				#endif

				Light mainLight = GetMainLight(shadowCoord, positionWS, shadowMask);
			#else
				Light mainLight = GetMainLight(shadowCoord);
			#endif

				// ambient or lightmap
				// Samples SH fully per-pixel. SampleSHVertex and SampleSHPixel functions
				// are also defined in case you want to sample some terms per-vertex.
				half3 bakedGI = SampleSH(normalWS);
				half occlusion = 1;

				half3 indirectDiffuse = bakedGI;
				indirectDiffuse *= occlusion * albedo * __ambientIntensity;
				emission += __emission;

				half3 lightDir = mainLight.direction;
				half3 lightColor = mainLight.color.rgb;

				half atten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;

				half ndl = dot(normalWS, lightDir);
				half3 ramp;
				
				half rampThreshold = __rampThreshold;
				half rampSmooth = __rampSmoothing * 0.5;
				half bandsCount = __bandsCount;
				half bandsSmoothing = __bandsSmoothing;
				ndl = saturate(ndl);
				half bandsNdl = smoothstep(rampThreshold - rampSmooth, rampThreshold + rampSmooth, ndl);
				half bandsSmooth = bandsSmoothing * 0.5;
				ramp = saturate((smoothstep(0.5 - bandsSmooth, 0.5 + bandsSmooth, frac(bandsNdl * bandsCount)) + floor(bandsNdl * bandsCount)) / bandsCount).xxx;

				// apply attenuation
				ramp *= atten;

				// Diffuse Tint
				half3 diffuseTint = saturate(__diffuseTint + ndl);
				ramp *= diffuseTint;
				
				half3 color = half3(0,0,0);
				// Rim Lighting
				#if defined(TCP2_RIM_LIGHTING)
				half rim = 1 - ndvRaw;
				rim = ( rim );
				half rimMin = __rimMin;
				half rimMax = __rimMax;
				rim = smoothstep(rimMin, rimMax, rim);
				half3 rimColor = __rimColor;
				half rimStrength = __rimStrength;
				//Rim light mask
				emission.rgb += ndl * atten * rim * rimColor * rimStrength;
				#endif
				half3 accumulatedRamp = ramp * max(lightColor.r, max(lightColor.g, lightColor.b));
				half3 accumulatedColors = ramp * lightColor.rgb;

				#if defined(TCP2_SPECULAR)
				//Anisotropic Specular
				half3 h = normalize(lightDir + viewDirWS);
				float ndh = max(0, dot (normalWS, h));
				half3 binorm = bitangentWS.xyz;
				float aX = dot(h, tangentWS) / __anisotropicSpread;
				float aY = dot(h, binorm) / __specularSmoothness;
				float specAniso = sqrt(max(0.0, ndl / ndvRaw)) * exp(-2.0 * (aX * aX + aY * aY) / (1.0 + ndh));
				float spec = smoothstep(__specularToonSize + __specularToonSmoothness, __specularToonSize - __specularToonSmoothness,1 - (specAniso / (1+__specularToonSmoothness)));
				spec = saturate(spec);
				spec *= atten;
				
				//Apply specular
				emission.rgb += spec * lightColor.rgb * __specularColor;
				#endif

				// Additional lights loop
			#ifdef _ADDITIONAL_LIGHTS
				uint pixelLightCount = GetAdditionalLightsCount();

				LIGHT_LOOP_BEGIN(pixelLightCount)
				{
					#if defined(URP_10_OR_NEWER)
						Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);
					#else
						Light light = GetAdditionalLight(lightIndex, positionWS);
					#endif
					half atten = light.shadowAttenuation * light.distanceAttenuation;

					#if defined(_LIGHT_LAYERS)
						half3 lightDir = half3(0, 1, 0);
						half3 lightColor = half3(0, 0, 0);
						if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
						{
							lightColor = light.color.rgb;
							lightDir = light.direction;
						}
					#else
						half3 lightColor = light.color.rgb;
						half3 lightDir = light.direction;
					#endif

					half ndl = dot(normalWS, lightDir);
					half3 ramp;
					
					ndl = saturate(ndl);
					half bandsNdl = smoothstep(rampThreshold - rampSmooth, rampThreshold + rampSmooth, ndl);
					half bandsSmooth = bandsSmoothing * 0.5;
					ramp = saturate((smoothstep(0.5 - bandsSmooth, 0.5 + bandsSmooth, frac(bandsNdl * bandsCount)) + floor(bandsNdl * bandsCount)) / bandsCount).xxx;

					// apply attenuation (shadowmaps & point/spot lights attenuation)
					ramp *= atten;

					// Diffuse Tint
					half3 diffuseTint = saturate(__diffuseTint + ndl);
					ramp *= diffuseTint;
					
					accumulatedRamp += ramp * max(lightColor.r, max(lightColor.g, lightColor.b));
					accumulatedColors += ramp * lightColor.rgb;

					#if defined(TCP2_SPECULAR)
					//Anisotropic Specular
					half3 h = normalize(lightDir + viewDirWS);
					float ndh = max(0, dot (normalWS, h));
					half3 binorm = bitangentWS.xyz;
					float aX = dot(h, tangentWS) / __anisotropicSpread;
					float aY = dot(h, binorm) / __specularSmoothness;
					float specAniso = sqrt(max(0.0, ndl / ndvRaw)) * exp(-2.0 * (aX * aX + aY * aY) / (1.0 + ndh));
					float spec = smoothstep(__specularToonSize + __specularToonSmoothness, __specularToonSize - __specularToonSmoothness,1 - (specAniso / (1+__specularToonSmoothness)));
					spec = saturate(spec);
					spec *= atten;
					
					//Apply specular
					emission.rgb += spec * lightColor.rgb * __specularColor;
					#endif
					#if defined(TCP2_RIM_LIGHTING)
					// Rim light mask
					half3 rimColor = __rimColor;
					half rimStrength = __rimStrength;
					emission.rgb += ndl * atten * rim * rimColor * rimStrength;
					#endif
				}
				LIGHT_LOOP_END
			#endif
			#ifdef _ADDITIONAL_LIGHTS_VERTEX
				color += input.vertexLights * albedo;
			#endif

				accumulatedRamp = saturate(accumulatedRamp);
				
				// Sketch
				#if defined(TCP2_SKETCH)
				half3 sketch = __sketchTexture;
				half sketchThresholdWidth = __sketchAntialiasing * fwidth(ndl);
				sketch = smoothstep(sketch - sketchThresholdWidth, sketch, clamp(saturate(accumulatedRamp * __sketchThresholdScale), __sketchMin, __sketchMax));
				#endif
				half3 shadowColor = (1 - accumulatedRamp.rgb) * __shadowColor;
				accumulatedRamp = accumulatedColors.rgb * __highlightColor + shadowColor;
				color += albedo * accumulatedRamp;
				#if defined(TCP2_SKETCH)
				color.rgb *= lerp(__sketchColor, half3(1,1,1), sketch.rgb);
				#endif

				// apply ambient
				color += indirectDiffuse;

				// Premultiply blending
				#if defined(_ALPHAPREMULTIPLY_ON)
					color.rgb *= alpha;
				#endif

				color += emission;

				// Mix the pixel color with fogColor. You can optionally use MixFogColor to override the fogColor with a custom one.
				float fogFactor = input.worldPosAndFog.w;
				color = MixFog(color, fogFactor);

				return half4(color, alpha);
			}
			ENDHLSL
		}

		// Depth & Shadow Caster Passes
		HLSLINCLUDE

		#if defined(SHADOW_CASTER_PASS) || defined(DEPTH_ONLY_PASS)

			#define fixed half
			#define fixed2 half2
			#define fixed3 half3
			#define fixed4 half4

			float3 _LightDirection;
			float3 _LightPosition;

			struct Attributes
			{
				float4 vertex   : POSITION;
				float3 normal   : NORMAL;
				float4 texcoord0 : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionCS     : SV_POSITION;
				float3 normal         : NORMAL;
				float3 pack0 : TEXCOORD1; /* pack0.xyz = positionWS */
				float2 pack1 : TEXCOORD2; /* pack1.xy = texcoord0 */
			#if defined(DEPTH_ONLY_PASS)
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			#endif
			};

			float4 GetShadowPositionHClip(Attributes input)
			{
				float3 positionWS = TransformObjectToWorld(input.vertex.xyz);
				float3 normalWS = TransformObjectToWorldNormal(input.normal);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif
				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				return positionCS;
			}

			Varyings ShadowDepthPassVertex(Attributes input)
			{
				Varyings output = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				#if defined(DEPTH_ONLY_PASS)
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
				#endif

				float3 worldNormalUv = mul(unity_ObjectToWorld, float4(input.normal, 1.0)).xyz;

				// Texture Coordinates
				output.pack1.xy.xy = input.texcoord0.xy * _BaseMap_ST.xy * _BaseMap_snow_ST.xy + _BaseMap_ST.zw + _BaseMap_snow_ST.zw;

				float3 worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
				output.normal = normalize(worldNormalUv);
				output.pack0.xyz = vertexInput.positionWS;

				#if defined(DEPTH_ONLY_PASS)
					output.positionCS = TransformObjectToHClip(input.vertex.xyz);
				#elif defined(SHADOW_CASTER_PASS)
					output.positionCS = GetShadowPositionHClip(input);
				#else
					output.positionCS = float4(0,0,0,0);
				#endif

				return output;
			}

			half4 ShadowDepthPassFragment(
				Varyings input
			) : SV_TARGET
			{
				#if defined(DEPTH_ONLY_PASS)
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
				#endif

				float3 positionWS = input.pack0.xyz;
				float3 normalWS = normalize(input.normal);

				// Sampled in Custom Code
				float4 imp_101 = _NoiseStrength_snow;
				// Shader Properties Sampling
				float4 __albedo = ( TCP2_TEX2D_SAMPLE(_BaseMap, _BaseMap, input.pack1.xy).rgba );
				float4 __albedo_snow = ( TCP2_TEX2D_SAMPLE(_BaseMap_snow, _BaseMap_snow, input.pack1.xy).rgba );
				float3 __highlightColor = ( _HColor.rgb );
				float4 __mainColor = ( _BaseColor.rgba * __highlightColor.rgbr );
				float4 __mainColor_snow = ( _BaseColor_snow.rgba );
				float __alpha = ( __albedo.a * __mainColor.a );
				float __layer_snow = saturate(  normalWS.y + _NormalThreshold_snow );
				float __contrast_snow = ( _contrast_snow );
				float __noise_snow = (  saturate( TCP2_TEX2D_SAMPLE_TRIPLANAR(_NoiseTexture_snow, _NoiseTexture_snow, float4(1, 1, 1, 1) * _NoiseTexture_snow_ST, positionWS, normalWS).r * imp_101 ) - imp_101 / 2.0 );

				// Material Layers Blending
				 __albedo = lerp(__albedo, __albedo_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));
				 __mainColor = lerp(__mainColor, __mainColor_snow, saturate(((__layer_snow + __noise_snow) + (__contrast_snow * 0.5 - 0.5)) / __contrast_snow));

				half3 viewDirWS = SafeNormalize(GetCameraPositionWS() - positionWS);
				half ndv = abs(dot(viewDirWS, normalWS));
				half ndvRaw = ndv;

				half3 albedo = half3(1,1,1);
				half alpha = __alpha;
				half3 emission = half3(0,0,0);

				return 0;
			}

		#endif
		ENDHLSL

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// using simple #define doesn't work, we have to use this instead
			#pragma multi_compile SHADOW_CASTER_PASS

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment ShadowDepthPassFragment

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

			ENDHLSL
		}

		Pass
		{
			Name "DepthOnly"
			Tags
			{
				"LightMode" = "DepthOnly"
			}

			ZWrite On
			ColorMask 0
			Cull [_Cull]

			HLSLPROGRAM

			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			//--------------------------------------
			// GPU Instancing
			#pragma multi_compile_instancing

			// using simple #define doesn't work, we have to use this instead
			#pragma multi_compile DEPTH_ONLY_PASS

			#pragma vertex ShadowDepthPassVertex
			#pragma fragment ShadowDepthPassFragment

			ENDHLSL
		}

	}

	FallBack "Hidden/InternalErrorShader"
	CustomEditor "ToonyColorsPro.ShaderGenerator.MaterialInspector_SG2"
}

/* TCP_DATA u config(ver:"2.9.6";unity:"2023.1.16f1";tmplt:"SG2_Template_URP";features:list["UNITY_5_4","UNITY_5_5","UNITY_5_6","UNITY_2017_1","UNITY_2018_1","UNITY_2018_2","UNITY_2018_3","UNITY_2019_1","UNITY_2019_2","UNITY_2019_3","UNITY_2019_4","UNITY_2020_1","UNITY_2021_1","UNITY_2021_2","UNITY_2022_2","RAMP_BANDS","SPECULAR","SPECULAR_SHADER_FEATURE","RIM","RIM_SHADER_FEATURE","BUMP","BUMP_SHADER_FEATURE","SKETCH_PROGRESSIVE_SMOOTH","SKETCH_AMBIENT","TT_SHADER_FEATURE","RIM_LIGHTMASK","TEXBLEND_NORMALIZE","SKETCH_SHADER_FEATURE","FOG","EMISSION","DIFFUSE_TINT","SKETCH_GRADIENT","AUTO_TRANSPARENT_BLENDING","SPECULAR_ANISOTROPIC","SPECULAR_TOON","OUTLINE_CONSTANT_SIZE","TEMPLATE_LWRP"];flags:list[];flags_extra:dict[];keywords:dict[RENDER_TYPE="Opaque",RampTextureDrawer="[TCP2Gradient]",RampTextureLabel="Ramp Texture",SHADER_TARGET="3.0",RIM_LABEL="Rim Lighting",BLEND_TEX1_CHNL="r"];shaderProperties:list[sp(name:"Albedo";imps:list[imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:True;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"white";locked_uv:False;uv:0;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Texcoord;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_BaseMap";md:"[MainTexture]";gbv:False;custom:False;refs:"";pnlock:False;guid:"622018fa-cf9c-40e1-b07a-d97562ba4ca4";op:Multiply;lbl:"Albedo";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a","105559","9816b9"];clones:dict[6b6d5a=sp(name:"Albedo_6b6d5a";imps:list[imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:True;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"white";locked_uv:False;uv:0;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Texcoord;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_BaseMap_6b6d5a";md:"[MainTexture]";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Albedo";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True),105559=sp(name:"Albedo_105559";imps:list[imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:True;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"white";locked_uv:False;uv:0;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Texcoord;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_BaseMap_105559";md:"[MainTexture]";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Albedo";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True),9816b9=sp(name:"Albedo_9816b9";imps:list[imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:True;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"white";locked_uv:False;uv:0;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Texcoord;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_BaseMap_9816b9";md:"[MainTexture]";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Albedo";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),sp(name:"Main Color";imps:list[imp_mp_color(def:RGBA(1, 1, 1, 1);hdr:True;cc:4;chan:"RGBA";prop:"_BaseColor";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"70af200f-ffce-4d8b-b49a-7d922bd434e5";op:Multiply;lbl:"Color";gpu_inst:False;locked:False;impl_index:0),imp_spref(cc:4;chan:"RGBR";lsp:"Highlight Color";guid:"49befde6-3b8c-4152-9c40-b077d987cc9a";op:Multiply;lbl:"Main Color";gpu_inst:False;locked:False;impl_index:-1)];layers:list["6b6d5a"];unlocked:list["6b6d5a","105559","9816b9"];clones:dict[6b6d5a=sp(name:"Main Color_6b6d5a";imps:list[imp_mp_color(def:RGBA(1, 1, 1, 1);hdr:True;cc:4;chan:"RGBA";prop:"_BaseColor_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Color";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True),105559=sp(name:"Main Color_105559";imps:list[imp_mp_color(def:RGBA(1, 1, 1, 1);hdr:True;cc:4;chan:"RGBA";prop:"_BaseColor_105559";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Color";gpu_inst:False;locked:False;impl_index:0),imp_spref(cc:4;chan:"RGBR";lsp:"Highlight Color";guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Main Color";gpu_inst:False;locked:False;impl_index:-1)];layers:list[];unlocked:list[];clones:dict[];isClone:True),9816b9=sp(name:"Main Color_9816b9";imps:list[imp_mp_color(def:RGBA(1, 1, 1, 1);hdr:True;cc:4;chan:"RGBA";prop:"_BaseColor_9816b9";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Color";gpu_inst:False;locked:False;impl_index:0),imp_spref(cc:4;chan:"RGBR";lsp:"Highlight Color";guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Main Color";gpu_inst:False;locked:False;impl_index:-1)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),,,,,,,,,sp(name:"Specular Color";imps:list[imp_mp_color(def:RGBA(0.5, 0.5, 0.5, 1);hdr:False;cc:3;chan:"RGB";prop:"_SpecularColor";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"2dcff822-b57e-4d12-ba06-fb5ff6b36dc6";op:Multiply;lbl:"Specular Color";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a"];clones:dict[6b6d5a=sp(name:"Specular Color_6b6d5a";imps:list[imp_mp_color(def:RGBA(0.5, 0.5, 0.5, 1);hdr:False;cc:3;chan:"RGB";prop:"_SpecularColor_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Specular Color";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),,,,,,,,,,,,,sp(name:"Sketch Texture";imps:list[imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:False;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:True;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"black";locked_uv:False;uv:6;cc:3;chan:"AAA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Triplanar;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_SketchTexture";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"f6c6f0d3-0dd1-4c01-9c83-00ce6e8cb5e7";op:Multiply;lbl:"Sketch Texture";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["9816b9"];clones:dict[9816b9=sp(name:"Sketch Texture_9816b9";imps:list[imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:False;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:True;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"black";locked_uv:False;uv:6;cc:3;chan:"AAA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Triplanar;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_SketchTexture_9816b9";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Texture";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),sp(name:"Sketch Color";imps:list[imp_constant(type:color;fprc:float;fv:1;f2v:(1, 1);f3v:(1, 1, 1);f4v:(1, 1, 1, 1);cv:RGBA(0, 0, 0, 1);guid:"33eb950e-fca5-456f-bb7f-d8379e409f82";op:Multiply;lbl:"Sketch Color";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a","9816b9"];clones:dict[6b6d5a=sp(name:"Sketch Color_6b6d5a";imps:list[imp_constant(type:color;fprc:float;fv:1;f2v:(1, 1);f3v:(1, 1, 1);f4v:(1, 1, 1, 1);cv:RGBA(0, 0, 0, 1);guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Color";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True),9816b9=sp(name:"Sketch Color_9816b9";imps:list[imp_constant(type:color;fprc:float;fv:1;f2v:(1, 1);f3v:(1, 1, 1);f4v:(1, 1, 1, 1);cv:RGBA(0, 0, 0, 1);guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Color";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),sp(name:"Sketch Threshold Scale";imps:list[imp_constant(type:float;fprc:float;fv:1;f2v:(1, 1);f3v:(1, 1, 1);f4v:(1, 1, 1, 1);cv:RGBA(1, 1, 1, 1);guid:"adddce03-1ca2-47a5-8e05-50bc87197f49";op:Multiply;lbl:"Sketch Threshold Scale";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a","9816b9"];clones:dict[6b6d5a=sp(name:"Sketch Threshold Scale_6b6d5a";imps:list[imp_constant(type:float;fprc:float;fv:1;f2v:(1, 1);f3v:(1, 1, 1);f4v:(1, 1, 1, 1);cv:RGBA(1, 1, 1, 1);guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Threshold Scale";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True),9816b9=sp(name:"Sketch Threshold Scale_9816b9";imps:list[imp_constant(type:float;fprc:float;fv:1;f2v:(1, 1);f3v:(1, 1, 1);f4v:(1, 1, 1, 1);cv:RGBA(1, 1, 1, 1);guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Threshold Scale";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),sp(name:"Sketch Min";imps:list[imp_mp_range(def:0;min:0;max:1;prop:"_SketchMin";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"a341918b-3b4a-4d7c-b8b6-b5ee375ea381";op:Multiply;lbl:"Sketch Min";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a","9816b9"];clones:dict[6b6d5a=sp(name:"Sketch Min_6b6d5a";imps:list[imp_mp_range(def:0;min:0;max:1;prop:"_SketchMin_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Min";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True),9816b9=sp(name:"Sketch Min_9816b9";imps:list[imp_mp_range(def:0;min:0;max:1;prop:"_SketchMin_9816b9";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Min";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),sp(name:"Sketch Max";imps:list[imp_mp_range(def:1;min:0;max:1;prop:"_SketchMax";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"4e7d4596-10a5-40b5-9c01-2c05ca5be226";op:Multiply;lbl:"Sketch Max";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a","9816b9"];clones:dict[6b6d5a=sp(name:"Sketch Max_6b6d5a";imps:list[imp_mp_range(def:1;min:0;max:1;prop:"_SketchMax_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Max";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True),9816b9=sp(name:"Sketch Max_9816b9";imps:list[imp_mp_range(def:1;min:0;max:1;prop:"_SketchMax_9816b9";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Max";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),sp(name:"Sketch Antialiasing";imps:list[imp_constant(type:float;fprc:float;fv:20;f2v:(1, 1);f3v:(1, 1, 1);f4v:(1, 1, 1, 1);cv:RGBA(1, 1, 1, 1);guid:"96a1c33d-601e-4758-9515-503c61f9eafc";op:Multiply;lbl:"Sketch Antialiasing";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a","9816b9"];clones:dict[6b6d5a=sp(name:"Sketch Antialiasing_6b6d5a";imps:list[imp_constant(type:float;fprc:float;fv:20;f2v:(1, 1);f3v:(1, 1, 1);f4v:(1, 1, 1, 1);cv:RGBA(1, 1, 1, 1);guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Antialiasing";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True),9816b9=sp(name:"Sketch Antialiasing_9816b9";imps:list[imp_constant(type:float;fprc:float;fv:20;f2v:(1, 1);f3v:(1, 1, 1);f4v:(1, 1, 1, 1);cv:RGBA(1, 1, 1, 1);guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Sketch Antialiasing";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),sp(name:"Progressive Sketch Smoothness";imps:list[imp_mp_range(def:0.1;min:0.005;max:0.5;prop:"_ProgressiveSketchSmoothness";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"a2e542a5-5db8-4ea8-9314-f4afd5dbda35";op:Multiply;lbl:"Progressive Smoothness";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a","9816b9"];clones:dict[6b6d5a=sp(name:"Progressive Sketch Smoothness_6b6d5a";imps:list[imp_mp_range(def:0.1;min:0.005;max:0.5;prop:"_ProgressiveSketchSmoothness_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Progressive Smoothness";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True),9816b9=sp(name:"Progressive Sketch Smoothness_9816b9";imps:list[imp_mp_range(def:0.1;min:0.005;max:0.5;prop:"_ProgressiveSketchSmoothness_9816b9";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Progressive Smoothness";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),,,,,,,,,,,,,,,,,,sp(name:"Specular Roughness PBR";imps:list[imp_mp_range(def:0.5;min:0;max:1;prop:"_SpecularRoughnessPBR";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"4e141120-b3d9-4970-a94e-6f1bcc141630";op:Multiply;lbl:"Roughness";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a"];clones:dict[6b6d5a=sp(name:"Specular Roughness PBR_6b6d5a";imps:list[imp_mp_range(def:0.5;min:0;max:1;prop:"_SpecularRoughnessPBR_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Roughness";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),sp(name:"Progressive Sketch Texture";imps:list[imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:False;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"black";locked_uv:False;uv:6;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Triplanar;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_ProgressiveSketchTexture";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"c8614fc9-1d1b-43bd-9587-b7757d76052d";op:Multiply;lbl:"Progressive Texture";gpu_inst:False;locked:False;impl_index:0)];layers:list["6b6d5a"];unlocked:list["6b6d5a"];clones:dict[6b6d5a=sp(name:"Progressive Sketch Texture_6b6d5a";imps:list[imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:False;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"black";locked_uv:False;uv:6;cc:4;chan:"RGBA";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Triplanar;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_ProgressiveSketchTexture_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"00000000-0000-0000-0000-000000000000";op:Multiply;lbl:"Progressive Texture";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:True)];isClone:False),sp(name:"Shadow Line Color";imps:list[imp_mp_color(def:RGBA(0, 0, 0, 1);hdr:True;cc:4;chan:"RGBA";prop:"_ShadowLineColor";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"3178b1a9-55af-476e-8446-eba216bedbf2";op:Multiply;lbl:"Color (RGB) Opacity (A)";gpu_inst:False;locked:False;impl_index:0)];layers:list[];unlocked:list[];clones:dict[];isClone:False)];customTextures:list[];codeInjection:codeInjection(injectedFiles:list[];mark:False);matLayers:list[ml(uid:"6b6d5a";name:"Snow";src:sp(name:"layer_6b6d5a";imps:list[imp_customcode(prepend_type:Disabled;prepend_code:"";prepend_file:"";prepend_file_block:"";preprend_params:dict[];code:"{2}.y + {3}";guid:"2aabce36-b3ee-4ee7-80b9-ac4e479b990e";op:Multiply;lbl:"layer_6b6d5a";gpu_inst:False;locked:False;impl_index:-1),imp_worldnorm(cc:1;chan:"Y";guid:"cb75b80f-dfa6-4fda-92cb-5e8fb76b06ad";op:Multiply;lbl:"layer_6b6d5a";gpu_inst:False;locked:False;impl_index:-1),imp_mp_float(def:1;prop:"_NormalThreshold_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"9d617f1d-9e50-467b-a458-0fdc230471cb";op:Multiply;lbl:"Normal Threshold";gpu_inst:False;locked:False;impl_index:-1)];layers:list[];unlocked:list[];clones:dict[];isClone:False);use_contrast:True;ctrst:sp(name:"contrast_6b6d5a";imps:list[imp_mp_range(def:0.5;min:0;max:1;prop:"_contrast_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"12972c69-ab0d-4964-8e44-c160ba1af87c";op:Multiply;lbl:"Contrast";gpu_inst:False;locked:False;impl_index:-1)];layers:list[];unlocked:list[];clones:dict[];isClone:False);use_noise:True;noise:sp(name:"noise_6b6d5a";imps:list[imp_customcode(prepend_type:Disabled;prepend_code:"";prepend_file:"";prepend_file_block:"";preprend_params:dict[];code:"saturate( {2}.r * {3} ) - {3} / 2.0";guid:"e30137e2-a38b-42d2-a807-9fda17e13fc7";op:Multiply;lbl:"noise_6b6d5a";gpu_inst:False;locked:False;impl_index:-1),imp_mp_texture(uto:True;tov:"";tov_lbl:"";gto:False;sbt:False;scr:False;scv:"";scv_lbl:"";gsc:False;roff:False;goff:False;sin_anm:False;sin_anmv:"";sin_anmv_lbl:"";gsin:False;notile:False;triplanar_local:False;def:"gray";locked_uv:False;uv:6;cc:1;chan:"R";mip:-1;mipprop:False;ssuv_vert:False;ssuv_obj:False;uv_type:Triplanar;uv_chan:"XZ";tpln_scale:1;uv_shaderproperty:__NULL__;uv_cmp:__NULL__;sep_sampler:__NULL__;prop:"_NoiseTexture_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"7b79c8ed-a0e1-4052-996d-6f8900c30d6c";op:Multiply;lbl:"Noise Texture";gpu_inst:False;locked:False;impl_index:-1),imp_mp_range(def:0.1;min:0;max:1;prop:"_NoiseStrength_6b6d5a";md:"";gbv:False;custom:False;refs:"";pnlock:False;guid:"ab73d421-0ebf-42d8-8e5e-ea7d6e567e17";op:Multiply;lbl:"Noise Strength";gpu_inst:False;locked:False;impl_index:-1)];layers:list[];unlocked:list[];clones:dict[];isClone:False))]) */
/* TCP_HASH c0db62d5766e0021385813a389eb7340 */
