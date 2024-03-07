using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/SRP")]
public class SRPAsset : RenderPipelineAsset
{
    [SerializeField]
    PostProcessSetting postprocessdata = new PostProcessSetting();

    protected override RenderPipeline CreatePipeline()
    {
        return new SRP(postprocessdata);
    }
}
