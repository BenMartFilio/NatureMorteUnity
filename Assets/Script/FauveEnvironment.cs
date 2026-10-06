using UnityEngine;


[ExecuteAlways]
public class FauveEnvironment : MonoBehaviour
{
    [Header("Hemisphere ambient (+ environnement analytique)")]
    public Color sky = new Color(0.40f, 0.45f, 0.90f);
    public Color horizon = new Color(0.95f, 0.65f, 0.55f);
    public Color ground = new Color(0.45f, 0.30f, 0.65f);
    [Range(0f, 2f)] public float ambientIntensity = 0.6f;

    [Header("Cubemap de reflet (Reflection Source = CustomCubemap)")]
    public Cubemap envCubemap;
    [Range(0f, 4f)] public float envIntensity = 1f;

    static readonly int SkyId = Shader.PropertyToID("_Fauve_SkyColor");
    static readonly int HorizonId = Shader.PropertyToID("_Fauve_HorizonColor");
    static readonly int GroundId = Shader.PropertyToID("_Fauve_GroundColor");
    static readonly int AmbId = Shader.PropertyToID("_Fauve_AmbientIntensity");
    static readonly int CubeId = Shader.PropertyToID("_Fauve_EnvCube");
    static readonly int CubeIntId = Shader.PropertyToID("_Fauve_EnvIntensity");

    void OnEnable() => Apply();
    void Update() => Apply();
    void OnValidate() => Apply();

    void Apply()
    {
        Shader.SetGlobalColor(SkyId, sky);
        Shader.SetGlobalColor(HorizonId, horizon);
        Shader.SetGlobalColor(GroundId, ground);
        Shader.SetGlobalFloat(AmbId, ambientIntensity);
        if (envCubemap != null) Shader.SetGlobalTexture(CubeId, envCubemap);
        Shader.SetGlobalFloat(CubeIntId, envCubemap != null ? envIntensity : 0f);
    }
}