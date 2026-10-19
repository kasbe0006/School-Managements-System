<template>
  <div class="py-4 flex flex-col gap-4">
    <div class="px-5 flex items-center justify-between">
      <h2 class="font-semibold text-2xl">Leave Applications</h2>
      <Button
        variant="solid"
        label="Apply Leave"
        icon-left="plus"
        @click="openNewLeaveDialog"
      />
    </div>

    <!-- Leave history list -->
    <div v-if="leaveResource.loading" class="px-5 text-gray-500 text-sm">
      Loading...
    </div>

    <div
      v-else-if="leaveResource.data && leaveResource.data.length > 0"
      class="px-5 flex flex-col gap-3"
    >
      <div
        v-for="leave in leaveResource.data"
        :key="leave.name"
        class="border rounded-lg p-4 flex flex-col gap-1 bg-white shadow-sm"
      >
        <div class="flex items-center justify-between">
          <span class="font-medium text-gray-800">{{ leave.name }}</span>
          <Badge
            variant="subtle"
            :theme="leaveStatusColor(leave.status)"
            size="md"
            :label="leave.status || 'Open'"
          />
        </div>
        <div class="text-sm text-gray-600">
          {{ formatDate(leave.from_date) }} → {{ formatDate(leave.to_date) }}
          <span class="ml-2 text-gray-400">({{ leave.total_days }} day{{ leave.total_days > 1 ? 's' : '' }})</span>
        </div>
        <div v-if="leave.reason" class="text-sm text-gray-500 italic">
          {{ leave.reason }}
        </div>
      </div>
    </div>

    <div v-else class="px-5">
      <MissingData message="No leave applications found" />
    </div>

    <!-- Apply Leave Dialog -->
    <Dialog
      v-model="showLeaveDialog"
      :options="{
        size: '2xl',
        title: 'Apply Leave',
      }"
    >
      <template #body-content>
        <NewLeave :newLeave="newLeave" />
      </template>
      <template #actions="{ close }">
        <div class="flex flex-row-reverse gap-2">
          <Button
            :disabled="
              !newLeave.from_date ||
              !newLeave.to_date ||
              !newLeave.total_days ||
              !newLeave.reason
            "
            :loading="applyLeave.loading"
            variant="solid"
            label="Submit"
            @click="submitLeave(close)"
          />
          <Button label="Cancel" @click="close()" />
        </div>
      </template>
    </Dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { Dialog, Badge, createResource } from 'frappe-ui'
import { studentStore } from '@/stores/student'
import NewLeave from '@/components/NewLeave.vue'
import MissingData from '@/components/MissingData.vue'
import { createToast } from '@/utils'

const { getStudentInfo, getCurrentProgram } = studentStore()
const studentInfo = getStudentInfo().value
const programName = getCurrentProgram().value?.program

const showLeaveDialog = ref(false)

const newLeave = reactive({
  student: studentInfo.student_name || '',
  student_name: studentInfo.student_name || '',
  from_date: '',
  to_date: '',
  reason: '',
  total_days: '',
})

function resetLeave() {
  newLeave.from_date = ''
  newLeave.to_date = ''
  newLeave.reason = ''
  newLeave.total_days = ''
}

function openNewLeaveDialog() {
  resetLeave()
  showLeaveDialog.value = true
}

// Fetch existing leave applications for this student
const leaveResource = createResource({
  url: 'frappe.client.get_list',
  params: {
    doctype: 'Student Leave Application',
    fields: ['name', 'from_date', 'to_date', 'total_days', 'reason', 'status'],
    filters: { student: studentInfo.name },
    order_by: 'creation desc',
    limit: 50,
  },
  auto: true,
})

const applyLeave = createResource({
  url: 'education.education.api.apply_leave',
  onSuccess: () => {
    showLeaveDialog.value = false
    leaveResource.reload()
    createToast({
      title: 'Leave applied successfully',
      icon: 'check',
      iconClasses: 'text-green-600',
    })
  },
  onError: (err) => {
    createToast({
      title: err.messages?.[0] ?? 'An error occurred',
      icon: 'x',
      iconClasses: 'text-red-600',
    })
  },
})

function submitLeave(close) {
  applyLeave.submit({
    leave_data: {
      student: studentInfo.name,
      student_name: studentInfo.student_name,
      from_date: newLeave.from_date,
      to_date: newLeave.to_date,
      reason: newLeave.reason,
      total_days: newLeave.total_days,
    },
    program_name: programName,
  })
}

function formatDate(dateStr) {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

function leaveStatusColor(status) {
  const map = {
    Approved: 'green',
    Rejected: 'red',
    Open: 'orange',
  }
  return map[status] || 'gray'
}
</script>
