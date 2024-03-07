using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class SRP : RenderPipeline
{
    CullingResults cullresult;
    ScriptableRender renderer;
    PostProcessSetting postprocessdata;

    public SRP(PostProcessSetting postdata)
    {
        postprocessdata = postdata;
        renderer = new ScriptableRender(postprocessdata);
    }



    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        //buffer = new CommandBuffer()
        //{
        //    name = "begain clean"
        //};
        //buffer.ClearRenderTarget(false, true, Color.green);
        //context.ExecuteCommandBuffer(buffer);
        //buffer.Release();

        SortCameras(cameras);

        //foreach(Camera cam in cameras)
        for(int i=0;i<cameras.Length;i++)
        {
            if (!cameras[i].TryGetCullingParameters(out ScriptableCullingParameters cullingParameters))
            {
                return;
            }
            cullresult = context.Cull(ref cullingParameters);
            renderer.RenderWithCamera(context,cullresult,cameras[i]);
            context.Submit();
        }
        //context.DrawGizmos(camera,GizmoSubset.PostImageEffects
    }

    void SortCameras(Camera[] cameras)
    {
        if (cameras.Length <= 1)
            return;
        Array.Sort(cameras, new CameraDataComparer());
    }

    class CameraDataComparer : IComparer<Camera>
    {
        public int Compare(Camera lhs, Camera rhs)
        {
            return (int)lhs.depth - (int)rhs.depth;
        }
    }
}
