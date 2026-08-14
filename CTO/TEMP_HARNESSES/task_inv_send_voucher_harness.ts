import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
const VERIFY_TOKEN = Deno.env.get("TASK_INV_HARNESS_TOKEN")!
const ADMIN = createClient(SUPABASE_URL, SERVICE_ROLE)

Deno.serve(async (req) => {
  if (new URL(req.url).searchParams.get("token") !== VERIFY_TOKEN) {
    return new Response(JSON.stringify({ success: false, msg: "Unauthorized harness" }), { status: 401 })
  }

  const company_id = "b4cc737e-6431-474e-af9e-92a427a44911"
  const main_branch_id = "319190b3-e277-4cf8-a712-a3b77acb9266"
  const item_id = "7ac41152-1fa4-43be-96d7-3cb23b767bbf"
  const item_code = "T028-ITEM"
  const before = await ADMIN.from("stock_branches").select("qty,allocated_qty").eq("branch_id", main_branch_id).eq("item_id", item_id).single()
  if (before.error) return new Response(JSON.stringify({ success: false, stage: "baseline", error: before.error.message }), { status: 500 })

  const email = `task-inv-${crypto.randomUUID()}@rawaea.invalid`
  const password = crypto.randomUUID() + "Aa1!"
  let authUserId: string | null = null
  let voucherId: string | null = null
  let detailId: string | null = null
  let voucherCode = ""

  try {
    const { data: created, error: createError } = await ADMIN.auth.admin.createUser({ email, password, email_confirm: true })
    if (createError || !created.user) throw new Error(createError?.message || "Auth user create failed")
    authUserId = created.user.id

    const LOGIN = createClient(SUPABASE_URL, SERVICE_ROLE)
    const { data: login, error: loginError } = await LOGIN.auth.signInWithPassword({ email, password })
    if (loginError || !login.session?.access_token) throw new Error(loginError?.message || "JWT acquisition failed")

    voucherId = crypto.randomUUID()
    detailId = crypto.randomUUID()
    voucherCode = `T028-HTTP-SV-${crypto.randomUUID().slice(0, 8)}`

    const { error: voucherError } = await ADMIN.from("stock_vouchers").insert({
      id: voucherId,
      company_id,
      voucher_code: voucherCode,
      voucher_date: new Date().toISOString().slice(0, 10),
      type: "Transfer",
      status: "Draft",
      from_type: "Branch",
      from_id: main_branch_id,
      source: "TASK-INV-HTTP-HARNESS",
    })
    if (voucherError) throw new Error(voucherError.message)

    const { error: detailError } = await ADMIN.from("stock_voucher_details").insert({
      id: detailId,
      voucher_id: voucherId,
      item_id,
      item_code,
      item_name: "TASK-INV-ITEM",
      qty: 1,
      received_qty: 0,
      created_at: new Date().toISOString(),
    })
    if (detailError) throw new Error(detailError.message)

    const endpoint = `${SUPABASE_URL}/functions/v1/send-stock-voucher`
    const headers = {
      Authorization: `Bearer ${login.session.access_token}`,
      apikey: SERVICE_ROLE,
      "Content-Type": "application/json",
    }

    const first = await fetch(endpoint, { method: "POST", headers, body: JSON.stringify({ voucher_code: voucherCode }) })
    const firstBody = await first.json()

    const afterFirst = await ADMIN.from("stock_branches").select("qty,allocated_qty").eq("branch_id", main_branch_id).eq("item_id", item_id).single()
    const logCountAfterFirst = await ADMIN.from("inventory_log").select("id", { count: "exact", head: true }).eq("voucher_id", voucherCode)
    const voucherAfterFirst = await ADMIN.from("stock_vouchers").select("status").eq("id", voucherId).single()

    const retry = await fetch(endpoint, { method: "POST", headers, body: JSON.stringify({ voucher_code: voucherCode }) })
    const retryBody = await retry.json()
    const afterRetry = await ADMIN.from("stock_branches").select("qty,allocated_qty").eq("branch_id", main_branch_id).eq("item_id", item_id).single()
    const logCountAfterRetry = await ADMIN.from("inventory_log").select("id", { count: "exact", head: true }).eq("voucher_id", voucherCode)

    const expectedFirst = first.status === 200 && firstBody?.success === true
    const stockMovedOnce = Number(before.data.qty) - Number(afterFirst.data.qty) === 1
    const retryRejected = retry.status >= 400 && retryBody?.success === false
    const noSecondMovement = Number(afterFirst.data.qty) === Number(afterRetry.data.qty)
    const oneLog = (logCountAfterFirst.count ?? 0) === 1 && (logCountAfterRetry.count ?? 0) === 1
    const statusSent = voucherAfterFirst.data?.status === "Sent"

    return new Response(JSON.stringify({
      success: expectedFirst && stockMovedOnce && retryRejected && noSecondMovement && oneLog && statusSent,
      first: { status: first.status, body: firstBody },
      retry: { status: retry.status, body: retryBody },
      baseline: before.data,
      after_first: afterFirst.data,
      after_retry: afterRetry.data,
      log_count_after_first: logCountAfterFirst.count,
      log_count_after_retry: logCountAfterRetry.count,
      voucher_status: voucherAfterFirst.data?.status,
      checks: { expectedFirst, stockMovedOnce, retryRejected, noSecondMovement, oneLog, statusSent },
      voucher_code: voucherCode,
    }), { headers: { "Content-Type": "application/json" } })
  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error instanceof Error ? error.message : String(error), voucher_code: voucherCode }), { status: 500, headers: { "Content-Type": "application/json" } })
  } finally {
    try {
      if (voucherCode) await ADMIN.from("inventory_log").delete().eq("voucher_id", voucherCode)
      if (detailId) await ADMIN.from("stock_voucher_details").delete().eq("id", detailId)
      if (voucherId) await ADMIN.from("stock_vouchers").delete().eq("id", voucherId)
      const current = await ADMIN.from("stock_branches").select("qty,allocated_qty").eq("branch_id", main_branch_id).eq("item_id", item_id).single()
      if (before.data && current.data && Number(current.data.qty) !== Number(before.data.qty)) {
        await ADMIN.from("stock_branches").update({ qty: before.data.qty, allocated_qty: before.data.allocated_qty }).eq("branch_id", main_branch_id).eq("item_id", item_id)
      }
      if (authUserId) await ADMIN.auth.admin.deleteUser(authUserId)
    } catch (_) {}
  }
})
