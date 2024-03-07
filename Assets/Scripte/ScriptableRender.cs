using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class ScriptableRender
{
    //ScriptableRenderContext context;
    //CullingResults result;
    //Camera cam;
    PostProcessSetting postset;
    public ScriptableRender(PostProcessSetting postprocesssetting)
    {
        postset = postprocesssetting;
    }
    ShaderTagId depthid = new ShaderTagId("MyDepth");
    ShaderTagId renderid = new ShaderTagId("SRPDefaultUnlit");
    ShaderTagId outlineid = new ShaderTagId("OutlinePass");
    ShaderTagId outlineid2 = new ShaderTagId("OutlinePass2");
    int camposid = Shader.PropertyToID("_CameraPos");
    int lightdirid = Shader.PropertyToID("_DirLightWay");
    int lightdir2id = Shader.PropertyToID("_DirLight2Way");
    int screentexid = Shader.PropertyToID("_ScreebTex");
    int bloommaskid = Shader.PropertyToID("_BloomMaskTex");
    int testtexid = Shader.PropertyToID("_TestTex");
    int depth1id = Shader.PropertyToID("_Depth1Tex");
    int depth2id = Shader.PropertyToID("_Depth2Tex");
    int shadow1marixid = Shader.PropertyToID("_Shadow1Matrix");
    int shadow2marixid = Shader.PropertyToID("_Shadow2Matrix");
    //int rendertexid = Shader.PropertyToID("_RenderTex");
    CommandBuffer buffer;

    public void RenderWithCamera(ScriptableRenderContext context, CullingResults result, Camera camera)
    {
        buffer = CommandBufferPool.Get(camera.name);

        if (camera.name == "topcamera")
        {
            Setup(context, buffer, camera);
            DrawDepth(context, result, camera, depth1id, shadow1marixid);
        }
        else if(camera.name=="sidecamera")
        {
            Setup(context, buffer, camera);
            DrawDepth(context, result, camera, depth2id, shadow2marixid);
        }
        else
        {
            Setup(context, buffer, camera);
            Execute(context, result, camera);
        }

        DrawGizmos(context, camera);
    }

    void DrawDepth(ScriptableRenderContext context,CullingResults result, Camera camera,int texindex,int shadowmatrixid)
    {
        //buffer.GetTemporaryRT(texindex, 1280, 720, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
        //Debug.Log(camera.name);
        SortingSettings sortsets = new SortingSettings(camera);
        DrawingSettings drawsets = new DrawingSettings(depthid, sortsets);
        FilteringSettings filtersets = new FilteringSettings(RenderQueueRange.all);
        context.DrawRenderers(result, ref drawsets, ref filtersets);
        buffer.GetTemporaryRT(texindex, 1280, 720, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
        buffer.Blit(BuiltinRenderTextureType.CameraTarget,texindex);
        buffer.SetGlobalMatrix(shadowmatrixid, GL.GetGPUProjectionMatrix(camera.projectionMatrix,true)*camera.worldToCameraMatrix);
        buffer.ClearRenderTarget(true, true, Color.black);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    void Execute(ScriptableRenderContext context,CullingResults result,Camera camera)
    {
        buffer.ClearRenderTarget(true, true, Color.cyan);
        buffer.SetGlobalVector(camposid, camera.transform.position);
        buffer.SetGlobalVector(lightdirid, -result.visibleLights[0].localToWorldMatrix.GetColumn(2));
        buffer.SetGlobalVector(lightdir2id, -result.visibleLights[1].localToWorldMatrix.GetColumn(2));
        //buffer.GetTemporaryRT(rendertexid, 1280, 720, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();


        
        //buffer.Clear();
        if(postset.bloomdata.bloomstate)
        {

            buffer.GetTemporaryRT(screentexid, 1280, 720, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
            buffer.GetTemporaryRT(bloommaskid, 1280, 720, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
            buffer.GetTemporaryRT(testtexid, 1280, 720, 32, FilterMode.Bilinear, RenderTextureFormat.Default);
            buffer.SetRenderTarget(testtexid, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare);
            buffer.ClearRenderTarget(true, true, Color.clear);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
            buffer.SetGlobalTexture(screentexid, testtexid);

        }

        SortingSettings sortsets = new SortingSettings(camera);
        DrawingSettings drawsets = new DrawingSettings(outlineid2, sortsets);
        FilteringSettings filtersets = new FilteringSettings(RenderQueueRange.all);
        context.DrawRenderers(result, ref drawsets, ref filtersets);

        buffer.ClearRenderTarget(true, false, Color.clear);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
        drawsets = new DrawingSettings(renderid, sortsets);
        drawsets.SetShaderPassName(1, outlineid);
        filtersets = new FilteringSettings(RenderQueueRange.all);
        context.DrawRenderers(result, ref drawsets, ref filtersets);

        //buffer.Blit(rendertexid, BuiltinRenderTextureType.CameraTarget);


        if (postset.bloomdata.bloomstate)
        {
            //buffer.Blit(testtexid, BuiltinRenderTextureType.CameraTarget,postset.bloomdata.selectmask);
            //context.ExecuteCommandBuffer(buffer);
            //buffer.Clear();
            buffer.SetGlobalTexture(screentexid,testtexid);

            buffer.SetRenderTarget(bloommaskid, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare);
            buffer.ClearRenderTarget(true, true, Color.clear);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();

            buffer.Blit(testtexid, bloommaskid, postset.bloomdata.selectmask);
            //buffer.ClearRenderTarget(true, true, Color.clear);
            //context.ExecuteCommandBuffer(buffer);
            //buffer.Clear();
            //buffer.ReleaseTemporaryRT(testtexid);
        
            buffer.Blit(bloommaskid, BuiltinRenderTextureType.CameraTarget);
            //buffer.ReleaseTemporaryRT(bloommaskid);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }
    }
    void Setup(ScriptableRenderContext context, CommandBuffer buffer,Camera camera)
    {
        context.SetupCameraProperties(camera);
        buffer.ClearRenderTarget(true,false,Color.gray);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    void DrawGizmos(ScriptableRenderContext context,Camera cam)
    {
        if (Handles.ShouldRenderGizmos())
        {
            context.DrawGizmos(cam, GizmoSubset.PreImageEffects);
            context.DrawGizmos(cam, GizmoSubset.PostImageEffects);
        }
    }
}
